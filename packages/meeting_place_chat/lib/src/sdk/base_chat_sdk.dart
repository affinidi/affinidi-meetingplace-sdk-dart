import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:matrix/matrix.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_chat.dart';
import '../loggers/logger_formatter.dart';
import '../protocol/protocol.dart' as protocol;
import '../utils/chat_utils.dart';
import '../utils/matrix_room_message_event.dart';
import '../utils/top_and_tail_extension.dart';
import 'chat.dart';

typedef SDKStreamSubscription =
    CoreSDKStreamSubscription<MediatorMessage, MediatorStreamProcessingResult>;

/// [BaseChatSDK] is an abstract base class that provides functionality
/// for Chat App implementations.
///
/// It is built on top of the Meeting Place Core SDK and leverages:
/// - **Decentralised Identifiers (DIDs)** for a globally unique
///   identifierfor secure interactions.
/// - **DIDComm Messaging v2.1 protocol** for a secure, private,
///   and trusted communications across systems.
///
/// Responsibilities:
/// - Manage chat lifecycle (start, resume, end).
/// - Subscribe to mediator channels for real-time events.
/// - Persist messages via [ChatRepository].
/// - Handle common message types (chat, reactions, deliveries,
///  presence, and effects).
/// - Dispatch live events through a [ChatStream].
abstract class BaseChatSDK {
  BaseChatSDK({
    required this.coreSDK,
    required this.did,
    required this.otherPartyDid,
    required this.mediatorDid,
    required this.chatRepository,
    required this.options,
    this.card,
    MeetingPlaceChatSDKLogger? logger,
  }) : _logger = LoggerFormatter(className: _className, baseLogger: logger),
       chatStream = ChatStream();

  static const String _className = 'BaseChatSDK';

  final MeetingPlaceCoreSDK coreSDK;
  final String did;
  final String otherPartyDid;
  final String mediatorDid;
  final ChatRepository chatRepository;
  final ChatSDKOptions options;
  final ContactCard? card;
  final MeetingPlaceChatSDKLogger _logger;

  MeetingPlaceChatSDKLogger get logger => _logger;

  ChatStream chatStream;
  SDKStreamSubscription? _mediatorStreamSubscription;
  Future<SDKStreamSubscription>? mediatorStreamFuture;

  MatrixTimelineEventStream? matrixSubscription;
  StreamSubscription<Event>? _matrixTimelineSubscription;
  StreamSubscription<List<String>>? _matrixTypingSubscription;
  StreamSubscription<CachedPresence>? _matrixPresenceSubscription;
  int? seqNo;

  String? _matrixRoomIdForThisChat;
  /// The current user's own Matrix user ID, set once [startChatSession] logs
  /// in to the Matrix server. Used to match against `m.mentions.user_ids`.
  String? ownMatrixUserId;

  /// Buffer for incoming Matrix reactions that arrive before the target
  /// `m.room.message` event has been persisted locally.
  ///
  /// Key: target Matrix eventId (the message), Value: unique emoji keys.
  final Map<String, Set<String>> _pendingMatrixReactionsByTargetEventId = {};

  /// Returns the Matrix roomId that this chat instance should listen to.
  ///
  /// - For 1:1 chats this is the direct room with the other party.
  /// - Subclasses (e.g. group chat) should override to return their room.
  @protected
  Future<String?> matrixRoomIdForTimelineFiltering() async {
    final otherMatrixUserId = await coreSDK.matrixUserIdForDid(
      did: did,
      targetDid: otherPartyDid,
    );
    return coreSDK.ensureDirectChatRoom(
      did: did,
      otherMatrixUserId: otherMatrixUserId,
    );
  }

  /// Sends a [PlainTextMessage] to the other party (implemented by subclasses).
  ///
  /// **Parameters:**
  /// - [message]: The plain text message to send.
  /// - [senderDid]: DID of the user who sent the message.
  /// - [recipientDid]: DID of the recipient of the message.
  /// - [mediatorDid]: Mediator DID for message routing.
  /// - [notify]: Whether to notify via mediator (default: `false`).
  /// - [ephemeral]: Whether the message should be ephemeral (default: `false`).
  /// - [forwardExpiryInSeconds]: Optional duration (in seconds) after which
  ///     the forwarded message is considered expired.
  @internal
  Future<void> sendPlainTextMessage(
    PlainTextMessage message, {
    required String senderDid,
    required String recipientDid,
    required String mediatorDid,
    bool notify = false,
    bool ephemeral = false,
    int? forwardExpiryInSeconds,
    List<String>? mentionUserIds,
  });

  /// Unique chat ID derived from [did] and [otherPartyDid].
  String get chatId =>
      ChatUtils.getChatId(did: did, otherPartyDid: otherPartyDid);

  /// Starts a chat session.
  ///
  /// - Initializes [ChatStream].
  /// - Subscribes to a mediator channel.
  /// - Retrieves persisted messages from repository.
  /// - Triggers a profile hash sync.
  ///
  /// **Returns:**
  /// - A [Chat] instance containing retrieves messages and channel reference.
  Future<Chat> startChatSession() async {
    final methodName = 'startChatSession';
    _logger.info('Starting chat session', name: methodName);

    chatStream = ChatStream();

    mediatorStreamFuture = subscribeToMediator();
    final messagesFuture = chatRepository.listMessages(chatId);

    unawaited(sendProfileHash());

    final messages = await messagesFuture;
    final chat = Chat(id: chatId, stream: chatStream, messages: messages);

    unawaited(
      mediatorStreamFuture!.then((subscription) {
        unawaited(fetchNewMessages());
        _mediatorStreamSubscription = subscription;
        subscription.listen((data) async {
          if (!await handleMessage(data, [])) {
            chatStream.pushData(
              StreamData(plainTextMessage: data.plainTextMessage),
            );
          }
          return MediatorStreamProcessingResult(keepMessage: false);
        });
      }),
    );

    final userId = await coreSDK.loginToMatrixServer(did);
    ownMatrixUserId = userId;

    // Determine which Matrix room this chat instance should handle.
    try {
      _matrixRoomIdForThisChat = await matrixRoomIdForTimelineFiltering();
    } catch (e) {
      _logger.warning(
        'Failed to resolve Matrix room for timeline filtering: $e',
        name: methodName,
      );
      _matrixRoomIdForThisChat = null;
    }

    matrixSubscription = await coreSDK.subscribeToMatrixTimeline(did);
    await _matrixTimelineSubscription?.cancel();
    _matrixTimelineSubscription = matrixSubscription!.listen((event) async {
      // Only process events for this chat's room (direct chat or group room).
      final roomFilter = _matrixRoomIdForThisChat;
      if (roomFilter != null && event.roomId != roomFilter) return;

      if (event.type == 'm.room.message') {
        // We persist and stream our own outbound messages locally at send time.
        // Skipping self-sent message events avoids duplicates.
        if (event.senderId == userId) return;
      final roomMessageEvent = MatrixRoomMessageEvent.fromTimelineEvent(event);

      if (options.onlyHandleMentionedMatrixMessages) {
        if (!roomMessageEvent.mentionsUser(userId)) return;
      }

      _logger.info(
        'Handling Matrix chat message event ${roomMessageEvent.eventId}',
        name: methodName,
      );

      final attachments = await _extractAttachmentsIfNeeded(
        roomMessageEvent.attachment,
        methodName: methodName,
      );

      final pendingReactions =
            _pendingMatrixReactionsByTargetEventId.remove(
              roomMessageEvent.eventId,
            ) ??
            <String>{};

      final chatMessage = Message(
        chatId: chatId,
        messageId: roomMessageEvent.eventId,
        senderDid: otherPartyDid,
        value: attachments.isNotEmpty ? '' : roomMessageEvent.body,
        isFromMe: false,
        dateCreated: roomMessageEvent.originServerTs,
        status: ChatItemStatus.received,
        attachments: attachments,
        mentionedUserIds: roomMessageEvent.mentionedUserIds,
        reactions: pendingReactions.toList(),
      );

      await chatRepository.createMessage(chatMessage);
      chatStream.pushData(StreamData(chatItem: chatMessage));
    return;
      }

      if (event.type == 'm.reaction') {
        final relatesTo = event.content['m.relates_to'];
        if (relatesTo is! Map) return;
        final relType = relatesTo['rel_type'];
        if (relType != 'm.annotation') return;

        final targetEventId = relatesTo['event_id'];
        final key = relatesTo['key'];
        if (targetEventId is! String || key is! String) return;

        final chatItem = await chatRepository.getMessage(
          chatId: chatId,
          messageId: targetEventId,
          );
      if (chatItem is! Message) {
          _pendingMatrixReactionsByTargetEventId
              .putIfAbsent(targetEventId, () => <String>{})
              .add(key);
          _logger.info(
            'Buffered Matrix reaction key=$key for missing target=${targetEventId.topAndTail()}',
            name: methodName,
          );
          return;
        }

        if (!chatItem.reactions.contains(key)) {
          chatItem.reactions.add(key);
          await chatRepository.updateMesssage(chatItem);
        }

        chatStream.pushData(StreamData(chatItem: chatItem));
      }
    });

    // Subscribe to Matrix typing notifications for 1:1 chats when we can
    // locate an existing direct-chat room.
    // try {
    //   final otherMatrixUserId = await coreSDK.matrixUserIdForDid(
    //     did: did,
    //     targetDid: otherPartyDid,
    //   );
    //   final directRoomId = await coreSDK.getExistingDirectChatRoomId(
    //     did: did,
    //     otherMatrixUserId: otherMatrixUserId,
    //   );

    try {
      final roomId = _matrixRoomIdForThisChat;
      if (roomId != null) {
        _matrixTypingSubscription = coreSDK
            .subscribeToMatrixTyping(did: did, roomId: roomId)
            .listen((typingUserIds) {
              final now = DateTime.now().toUtc();
              chatStream.pushData(
                StreamData(
                  plainTextMessage: PlainTextMessage(
                    id: const Uuid().v4(),
                    type: Uri.parse(ChatProtocol.chatActivity.value),
                    from: typingUserIds.isEmpty ? null : otherPartyDid,
                    to: [did],
                    body: {'timestamp': now.toIso8601String()},
                    createdTime: now,
                  ),
                ),
              );
            });
      }
    } catch (e) {
      _logger.warning(
        'Failed to subscribe to Matrix typing notifications: $e',
        name: methodName,
      );
    }

    // Subscribe to Matrix presence updates for 1:1 chats.
    try {
      final otherMatrixUserId = await coreSDK.matrixUserIdForDid(
        did: did,
        targetDid: otherPartyDid,
      );
      _matrixPresenceSubscription = coreSDK
          .subscribeToMatrixPresence(did: did, userIds: {otherMatrixUserId})
          .listen((presence) {
            final now = DateTime.now().toUtc();
            chatStream.pushData(
              StreamData(
                plainTextMessage: PlainTextMessage(
                  id: const Uuid().v4(),
                  type: Uri.parse(ChatProtocol.chatPresence.value),
                  from: otherPartyDid,
                  to: [did],
                  body: {
                    'timestamp': now.toIso8601String(),
                    'presence': presence.presence.name,
                    if (presence.statusMsg != null)
                      'statusMsg': presence.statusMsg,
                    if (presence.currentlyActive != null)
                      'currentlyActive': presence.currentlyActive,
                    if (presence.lastActiveTimestamp != null)
                      'lastActiveTimestamp': presence.lastActiveTimestamp!
                          .toIso8601String(),
                  },
                  createdTime: now,
                ),
              ),
            );
          });
    } catch (e) {
      _logger.warning(
        'Failed to subscribe to Matrix presence notifications: $e',
        name: methodName,
      );
    }

    return chat;
  }

  Future<List<Attachment>> _extractAttachmentsIfNeeded(
    MatrixRoomMessageAttachment? roomMessageAttachment, {
    required String methodName,
  }) async {
    if (roomMessageAttachment == null) {
      return const [];
    }

    final attachmentId = const Uuid().v4();
    final attachment = Attachment(
      id: attachmentId,
      format: roomMessageAttachment.format,
      filename: roomMessageAttachment.filename,
      mediaType: roomMessageAttachment.mediaType,
      data: AttachmentData(
        links: [Uri.parse(roomMessageAttachment.uri)],
        json: roomMessageAttachment.metadataJson,
      ),
    );

    if (!ChatSDK.isAutomaticDownloadEnabled()) {
      return [attachment];
    }

    try {
      final hydratedAttachment = await coreSDK.downloadAttachment(
        did: did,
        attachment: attachment,
      );

      return [hydratedAttachment];
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to download Matrix media for ${roomMessageAttachment.uri}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );

      return [
        Attachment(
          id: attachment.id,
          format: attachment.format,
          filename: attachment.filename,
          mediaType: attachment.mediaType,
          data: attachment.data,
        ),
      ];
    }
  }

  /// Waits until the mediator channel subscription is ready. Stream of live
  /// chat events ([StreamData]) for this session.
  ///
  /// **Returns:**
  /// - A [ChatStream] or `null` if the chat session has not yet started
  ///   or resumed.
  Future<ChatStream?> get chatStreamSubscription async {
    if (mediatorStreamFuture == null) return null;
    await mediatorStreamFuture;
    return chatStream;
  }

  /// Retrieves all persisted messages for this chat.
  Future<List<ChatItem>> get messages {
    final methodName = 'messages';
    _logger.info('Retrieving all persisted messages', name: methodName);
    return chatRepository.listMessages(chatId);
  }

  /// Retrieves a single message by ID.
  ///
  /// **Parameters:**
  /// - [messageId]: Unique message identifier.
  ///
  /// **Returns:**
  /// - A [ChatItem] if found, or `null`.
  Future<ChatItem?> getMessageById(String messageId) {
    final methodName = 'getMessageById';
    _logger.info('Retrieving message by ID: $messageId', name: methodName);
    return chatRepository.getMessage(chatId: chatId, messageId: messageId);
  }

  /// Stream of live chat events ([StreamData]) for this session.
  ///
  /// **Throws:**
  /// - [Exception] if the chat has not been started first.
  Stream<StreamData> get stream {
    final methodName = 'stream';
    _logger.info('Returning chat event stream...', name: methodName);
    return chatStream.stream;
  }

  /// Handles an incoming [PlainTextMessage].
  ///
  /// Supported message types:
  /// - **Chat message**: Persisted and pushed downstream.
  /// - **Reaction**: Updates existing message reactions.
  /// - **AliasProfileHash / AliasProfileRequest**: Validates or creates concierge messages.
  /// - **Delivered**: Marks referenced messages as delivered.
  /// - **ContactDetailsUpdate**: Updates channel contact card.
  /// - **Activity / Presence / Effect**: Pushed downstream as events.
  ///
  /// **Parameters:**
  /// - [MediatorMessage]: The incoming [MediatorMessage] to process.
  /// - [messages]: A list to collect new [Message] instances.
  ///
  /// Returns a boolean indicating whether the message was handled.
  @internal
  Future<bool> handleMessage(
    MediatorMessage message,
    List<Message> messages,
  ) async {
    final methodName = 'handleMessage';
    _logger.info(
      '''Starting to handle incoming message of type ${message.plainTextMessage.type}''',
      name: methodName,
    );

    // Ignore non-chat DIDComm messages (e.g., messagepickup status) to avoid
    // failing on channel resolution for unrelated traffic.
    final typeValue = message.plainTextMessage.type.toString();
    if (ChatProtocol.byValue(typeValue) == null) {
      _logger.info(
        'Ignoring non-chat message type=$typeValue',
        name: methodName,
      );
      return true;
    }

    final channel = await getChannel();
    if (_requiresAcknowledgement(message.plainTextMessage)) {
      unawaited(sendChatDeliveredMessage(message.plainTextMessage));
    }

    if (_requiresSequenceNumberUpdate(message.plainTextMessage)) {
      final messageSequenceNumber = message.messageSequenceNumber;
      if (messageSequenceNumber != null &&
          messageSequenceNumber > channel.seqNo) {
        channel.seqNo = messageSequenceNumber;
        seqNo = messageSequenceNumber;
        await coreSDK.updateChannel(channel);
      }
    }

    // if (MessageUtils.isType(
    //   message.plainTextMessage,
    //   ChatProtocol.chatMessage,
    // )) {
    //   _logger.info('Handling chat message', name: methodName);
    //   final chatMessage = Message.fromReceivedMessage(
    //     message: ChatMessage.fromPlainTextMessage(message.plainTextMessage),
    //     chatId: chatId,
    //   );
    //   await chatRepository.createMessage(chatMessage);

    //   chatStream.pushData(
    //     StreamData(
    //       plainTextMessage: message.plainTextMessage,
    //       chatItem: chatMessage,
    //     ),
    //   );
    //   return true;
    // }

    if (message.plainTextMessage.type.toString() ==
        ChatProtocol.chatReaction.value) {
      _logger.info('Handling chat reaction message', name: methodName);
      final chatReactionMessage = ChatReaction.fromPlainTextMessage(
        message.plainTextMessage,
      );

      final repositoryMessage = await chatRepository.getMessage(
        chatId: chatId,
        messageId: chatReactionMessage.body.messageId,
      );

      if (repositoryMessage is! Message) {
        final message = 'Reactions only supported for chat messages';
        _logger.error(message, name: methodName);
        throw Exception(message);
      }

      repositoryMessage.reactions = chatReactionMessage.body.reactions;
      await chatRepository.updateMesssage(repositoryMessage);

      chatStream.pushData(
        StreamData(
          plainTextMessage: message.plainTextMessage,
          chatItem: repositoryMessage,
        ),
      );
      return true;
    }

    if (message.plainTextMessage.type.toString() ==
        ChatProtocol.chatAliasProfileHash.value) {
      _logger.info(
        'Handling chat alias profile hash message',
        name: methodName,
      );
      if (channel.type != ChannelType.group) {
        final profileHash = message.plainTextMessage.body?['profile_hash'];
        if (profileHash != null && profileHash is String) {
          if (channel.otherPartyContactCard != null &&
              _contactHash(channel.otherPartyContactCard!) == profileHash) {
            chatStream.pushData(
              StreamData(plainTextMessage: message.plainTextMessage),
            );
            return true;
          }

          await sendPlainTextMessage(
            protocol.ChatAliasProfileRequest.create(
              from: did,
              to: [otherPartyDid],
              profileHash: profileHash,
            ).toPlainTextMessage(),
            senderDid: did,
            recipientDid: otherPartyDid,
            mediatorDid: mediatorDid,
          );

          chatStream.pushData(
            StreamData(plainTextMessage: message.plainTextMessage),
          );
        } else {
          _logger.warning(
            'Skip processing chatAliasProfileHash message '
            'because of empty profile hash',
            name: methodName,
          );
        }
      }
      return true;
    }

    if (message.plainTextMessage.type.toString() ==
        ChatProtocol.chatAliasProfileRequest.value) {
      _logger.info(
        'Handling chat alias profile request message',
        name: methodName,
      );
      if (channel.type != ChannelType.group) {
        // TODO: delete old concierge messages

        final conciergeMessage = ConciergeMessage(
          chatId: chatId,
          messageId: message.plainTextMessage.id,
          senderDid: message.plainTextMessage.from!,
          isFromMe: false,
          dateCreated:
              message.plainTextMessage.createdTime ?? DateTime.now().toUtc(),
          status: ChatItemStatus.userInput,
          conciergeType: ConciergeMessageType.permissionToUpdateProfile,
          data: {
            'profileHash': message.plainTextMessage.body?['profile_hash'],
            'replyTo': message.plainTextMessage.from,
          },
        );

        await chatRepository.createMessage(conciergeMessage);
        chatStream.pushData(
          StreamData(
            plainTextMessage: message.plainTextMessage,
            chatItem: conciergeMessage,
          ),
        );
      }
      return true;
    }

    if (message.plainTextMessage.type.toString() ==
        ChatProtocol.chatDelivered.value) {
      _logger.info('Handling chat delivered message', name: methodName);
      final messageIds = _getMessageIdsFromChatDelivered(
        message.plainTextMessage,
      );
      for (final messageId in messageIds) {
        final targetMessage = await chatRepository.getMessage(
          chatId: chatId,
          messageId: messageId,
        );

        if (targetMessage == null) {
          final message = 'Message not found';
          _logger.error(message, name: methodName);
          // throw Exception('Message not found');
          continue;
        }

        targetMessage.status = ChatItemStatus.delivered;
        await chatRepository.updateMesssage(targetMessage);

        chatStream.pushData(
          StreamData(
            plainTextMessage: message.plainTextMessage,
            chatItem: targetMessage,
          ),
        );
      }
      return true;
    }

    if (message.plainTextMessage.type.toString() ==
        ChatProtocol.chatContactDetailsUpdate.value) {
      _logger.info(
        'Handling chat contact details update message',
        name: methodName,
      );
      if (channel.type != ChannelType.group) {
        channel.otherPartyContactCard = ContactCard.fromJson(
          message.plainTextMessage.body!,
        );

        await coreSDK.updateChannel(channel);
        chatStream.pushData(
          StreamData(plainTextMessage: message.plainTextMessage),
        );
      }
      return true;
    }

    if (message.plainTextMessage.isOfType(ChatProtocol.chatActivity.value)) {
      _logger.info('Handling chat activity message', name: methodName);
      chatStream.pushData(
        StreamData(plainTextMessage: message.plainTextMessage),
      );
      return true;
    }

    if (message.plainTextMessage.type.toString() ==
        ChatProtocol.chatPresence.value) {
      _logger.info('Handling chat presence message', name: methodName);
      chatStream.pushData(
        StreamData(plainTextMessage: message.plainTextMessage),
      );
      return true;
    }

    if (message.plainTextMessage.type.toString() ==
        ChatProtocol.chatEffect.value) {
      _logger.info('Handling chat effect message', name: methodName);
      chatStream.pushData(
        StreamData(plainTextMessage: message.plainTextMessage),
      );

      return true;
    }

    return false;
  }

  /// Fetch new messages from the mediator and process them via [handleMessage].
  ///
  /// **Returns:**
  /// - A list of newly processed [Message]s.
  Future<List<Message>> fetchNewMessages() async {
    final methodName = 'fetchNewMessages';
    _logger.info('Started fetching new messages', name: methodName);
    final messagesFromMediator = await coreSDK.fetchMessages(
      did: did,
      mediatorDid: mediatorDid,
      deleteOnRetrieve: false,
    );
    final newMessages = <Message>[];
    final processedHashes = <String>[];

    for (final message in messagesFromMediator) {
      if (!await handleMessage(message, newMessages)) {
        chatStream.pushData(
          StreamData(plainTextMessage: message.plainTextMessage),
        );
      }
      processedHashes.add(message.messageHash!);
    }

    if (processedHashes.isNotEmpty) {
      await coreSDK.deleteMessages(
        did: did,
        mediatorDid: mediatorDid,
        messageHashes: processedHashes,
      );
    }

    _logger.info(
      'Completed loading new messages: ${newMessages.length} new messages',
      name: methodName,
    );
    return newMessages;
  }

  /// Subscribes to mediator channel for real-time updates.
  ///
  /// **Returns:**
  /// - A [SDKStreamSubscription] subscription.
  ///
  /// **Throws:**
  /// - [Exception] if the chat session has not yet started or resumed.
  @internal
  Future<SDKStreamSubscription> subscribeToMediator() {
    return coreSDK.subscribeToMediator(
      did,
      mediatorDid: mediatorDid,
      options: MediatorStreamSubscriptionOptions(
        expectedMessageWrappingTypes:
            coreSDK.options.expectedMessageWrappingTypes,
        fetchMessagesOnConnect: false,
      ),
    );
  }

  /// Sends a custom [PlainTextMessage] using the chat's sender and recipient
  /// DIDs. No chat item is created or persisted for this type of operation.
  ///
  /// **Parameters:**
  /// - [message]: The [PlainTextMessage] to send.
  ///
  /// Returns a [Future] that completes when the message has been sent.
  Future<void> sendMessage(PlainTextMessage message, {bool notify = false}) {
    final senderDid = message.from;
    if (senderDid == null || senderDid != did) {
      throw Exception(
        'Message "from" DID ${message.from} does not match chat sender DID $did.',
      );
    }

    final recipientDid = message.to?.firstOrNull;
    if (recipientDid == null || recipientDid != otherPartyDid) {
      throw Exception(
        'Message "to" DID ${message.to} does not match chat recipient DID $otherPartyDid.',
      );
    }

    return sendPlainTextMessage(
      PlainTextMessage.fromJson({
        ...message.toJson(),
        'from': senderDid,
        'to': [recipientDid],
      }),
      senderDid: senderDid,
      recipientDid: recipientDid,
      mediatorDid: mediatorDid,
      notify: notify,
    );
  }

  /// Sends a plain text message with optional attachments.
  ///
  /// **Parameters:**
  /// - [text]: The plain text content of the message.
  /// - [attachments]: Optional list of [Attachment]s included with the message.
  ///
  /// **Returns:**
  /// - The sent [Message] object persisted in the repository.
  Future<Message> sendTextMessage(
    String text, {
    List<Attachment>? attachments,
    List<String>? mentionUserIds,
  }) async {
    final methodName = 'sendTextMessage';
    _logger.info('Started sending text message', name: methodName);

    final channel = await getChannel();
    channel.increaseSeqNo();

    final chatMessage = protocol.ChatMessage.create(
      from: did,
      to: [otherPartyDid],
      text: text,
      seqNo: channel.seqNo,
      attachments: attachments ?? [],
    );

    final plainTextMessage = chatMessage.toPlainTextMessage();
    final createdMessage = await chatRepository.createMessage(
      Message.fromSentMessage(message: chatMessage, chatId: chatId),
    );

    try {
      chatStream.pushData(
        StreamData(
          plainTextMessage: plainTextMessage,
          chatItem: createdMessage,
        ),
      );

      await _sendMessageWithNotification(
        plainTextMessage,
        mentionUserIds: mentionUserIds,
      );

      final updatedMessage = await _updateMessageStatus(
        chatId: chatId,
        messageId: createdMessage.messageId,
      );

      await coreSDK.updateChannel(channel);

      chatStream.pushData(
        StreamData(
          plainTextMessage: plainTextMessage,
          chatItem: updatedMessage,
        ),
      );

      _logger.info('Completed sending text message', name: methodName);
      return updatedMessage;
    } catch (e, stackTrace) {
      return await _handleSendMessageError(
        createdMessage: createdMessage,
        chatMessage: plainTextMessage,
        error: e,
        stackTrace: stackTrace,
        methodName: methodName,
      );
    }
  }

  /// Starts periodic chat presence updates.
  Future<void> startChatPresenceUpdates() async {}

  /// Sends an offline presence signal to Matrix.
  Future<void> sendOfflinePresence() async {
    final methodName = 'sendOfflinePresence';
    try {
      await coreSDK.setMatrixPresence(did: did, presence: PresenceType.offline);
    } catch (e) {
      _logger.warning(
        'Failed to set Matrix offline presence: $e',
        name: methodName,
      );
    }
  }

  /// Sends a chat presence signal to the other party.
  Future<void> sendChatPresence() async {
    final methodName = 'sendChatPresence';
    try {
      // Presence is per Matrix user, not per chat/channel.
      await coreSDK.setMatrixPresence(did: did, presence: PresenceType.online);
    } catch (e) {
      _logger.warning('Failed to set Matrix presence: $e', name: methodName);
    }
  }

  /// Sends a profile hash update if the contact card has changed.
  Future<void> sendProfileHash() async {
    final methodName = 'sendProfileHash';
    _logger.info('Started sending profile hash', name: methodName);
    if (card == null) {
      _logger.info(
        'ContactCard is null, skipping profile hash update',
        name: methodName,
      );
      return;
    }

    final channel = await getChannel();
    if (channel.contactCard != null && !card!.equals(channel.contactCard!)) {
      await sendPlainTextMessage(
        protocol.ChatAliasProfileHash.create(
          from: did,
          to: [otherPartyDid],
          profileHash: _contactHash(card!),
        ).toPlainTextMessage(),
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
      );

      channel.contactCard = card;
      await coreSDK.updateChannel(channel);
    }

    _logger.info('Completed sending profile hash', name: methodName);
  }

  /// Extracts message IDs from a delivered plain text message.
  ///
  /// **Parameters:**
  /// - [message]: The [PlainTextMessage] containing a list of message IDs
  ///   in its body.
  ///
  /// **Returns:**
  /// - A list of [String] message IDs.
  List<String> _getMessageIdsFromChatDelivered(PlainTextMessage message) {
    return List<String>.from(message.body!['messages'] as List<dynamic>);
  }

  bool _requiresAcknowledgement(PlainTextMessage message) {
    return options.requiresAcknowledgement.contains(
      ChatProtocol.byValue(message.type.toString()),
    );
  }

  bool _requiresSequenceNumberUpdate(PlainTextMessage message) {
    return coreSDK.options.messageTypesForSequenceTracking.contains(
      message.type.toString(),
    );
  }

  /// Sends a "delivered" acknowledgement for a received message.
  Future<void> sendChatDeliveredMessage(PlainTextMessage message) async {
    final methodName = 'sendChatDeliveredMessage';
    _logger.info('Started sending chat delivered message', name: methodName);
    await sendPlainTextMessage(
      protocol.ChatDelivered.create(
        from: did,
        to: [otherPartyDid],
        messages: [message.id],
      ).toPlainTextMessage(),
      senderDid: did,
      recipientDid: otherPartyDid,
      mediatorDid: mediatorDid,
    );

    _logger.info('Completed sending chat delivered message', name: methodName);
  }

  /// Sends updated contact details from the current contact card.
  ///
  /// **Throws:**
  /// - [Exception] if the [card] is missing.
  Future<void> sendChatContactDetailsUpdate(ConciergeMessage message) async {
    final methodName = 'sendChatContactDetailsUpdate';
    _logger.info(
      'Started sending chat contact details update',
      name: methodName,
    );
    if (card == null) {
      final message = 'ContactCard missing for contact details update';
      _logger.error(message, name: methodName);
      // throw Exception('ContactCard missing for contact details update');
    }

    unawaited(
      sendPlainTextMessage(
        protocol.ChatContactDetailsUpdate.create(
          from: did,
          to: [otherPartyDid],
          profileDetails: card!.toJson(),
        ).toPlainTextMessage(),
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
      ),
    );

    message.status = ChatItemStatus.confirmed;
    await chatRepository.updateMesssage(message);
    chatStream.pushData(StreamData(chatItem: message));

    _logger.info(
      'Completed sending chat contact details update',
      name: methodName,
    );
  }

  /// Rejects a contact details update and marks message as confirmed.
  Future<void> rejectChatContactDetailsUpdate(ConciergeMessage message) async {
    final methodName = 'rejectChatContactDetailsUpdate';
    _logger.info(
      'Started rejecting chat contact details update',
      name: methodName,
    );
    message.status = ChatItemStatus.confirmed;
    await chatRepository.updateMesssage(message);
    _logger.info(
      'Completed rejecting chat contact details update',
      name: methodName,
    );

    chatStream.pushData(StreamData(chatItem: message));
  }

  /// Reacts (or unreacts) to a chat message with an emoji or symbol.
  ///
  /// **Parameters:**
  /// - [message]: The target [Message].
  /// - [reaction]: The reaction data (e.g., emoji).
  ///
  /// **Throws:**
  /// - Rolls back local reaction if sending fails.
  Future<void> reactOnMessage(
    Message message, {
    required String reaction,
  }) async {
    final methodName = 'reactOnMessage';
    _logger.info('Started reacting on message (Matrix)', name: methodName);

    // Reactions are Matrix-based and require Matrix event IDs.
    if (!message.messageId.startsWith(r'$')) {
      _logger.warning(
        'Skipping reaction for non-Matrix messageId=${message.messageId.topAndTail()} '
        '(expected Matrix event IDs to start with \$).',
        name: methodName,
      );
      return;
    }

    final ownMxid = ownMatrixUserId;
    if (ownMxid == null || ownMxid.trim().isEmpty) {
      _logger.warning(
        'Skipping reaction because ownMatrixUserId is not available yet.',
        name: methodName,
    );
    return;
    }

    final roomId =
        _matrixRoomIdForThisChat ??
        await matrixRoomIdForTimelineFiltering();

    if (roomId == null || roomId.trim().isEmpty) {
      _logger.warning(
        'Skipping reaction because Matrix roomId is not available for this chat.',
        name: methodName,
      );
      return;
    }

    await sendMatrixReaction(
      message: message,
      reaction: reaction,
      roomId: roomId,
    );

    _logger.info('Completed reacting on message (Matrix)', name: methodName);
  }

  @protected
  Future<void> sendMatrixReaction({
    required Message message,
    required String reaction,
    required String roomId,
  }) async {
    await coreSDK.sendMatrixReaction(
      did: did,
      roomId: roomId,
      targetEventId: message.messageId,
      key: reaction,
    );

    if (!message.reactions.contains(reaction)) {
      message.reactions.add(reaction);
    }
    await chatRepository.updateMesssage(message);
    chatStream.pushData(StreamData(chatItem: message));
  }

  /// Sends a chat effect (visual/animated signal).
  Future<void> sendEffect(Effect effect) async {
    final methodName = 'sendEffect';
    _logger.info('Started sending chat effect', name: methodName);
    final chatEffect = protocol.ChatEffect.create(
      from: did,
      to: [otherPartyDid],
      effect: effect.name,
    ).toPlainTextMessage();

    chatStream.pushData(StreamData(plainTextMessage: chatEffect));

    // TODO: handle error case
    await sendPlainTextMessage(
      chatEffect,
      senderDid: did,
      recipientDid: otherPartyDid,
      mediatorDid: mediatorDid,
    );
    _logger.info('Completed sending chat effect', name: methodName);
  }

  /// Sends a chat activity message.
  Future<void> sendChatActivity() async {
    final methodName = 'sendChatActivity';
    _logger.info('Started sending chat activity', name: methodName);
    try {
      final roomId =
          _matrixRoomIdForThisChat ??
          await matrixRoomIdForTimelineFiltering();
      if (roomId == null || roomId.trim().isEmpty) {
        _logger.warning(
          'Skipping Matrix typing notification because roomId is not available for this chat.',
          name: methodName,
      );
      return;
      }
      await coreSDK.setMatrixTyping(
        did: did,
        roomId: roomId,
        isTyping: true,
        timeoutMs: options.chatActivityExpiry.inMilliseconds,
      );
    } catch (e) {
      _logger.warning(
        'Failed to send Matrix typing notification: $e',
        name: methodName,
      );
    }
    _logger.info('Completed sending chat activity', name: methodName);
  }

  /// Ends the chat session, disposing of the channel and stream manager.
  Future<void> end() async {
    await _mediatorStreamSubscription?.dispose();
    _mediatorStreamSubscription = null;
    mediatorStreamFuture = null;
    await _matrixTimelineSubscription?.cancel();
    _matrixTimelineSubscription = null;
    await _matrixTypingSubscription?.cancel();
    _matrixTypingSubscription = null;
    await _matrixPresenceSubscription?.cancel();
    _matrixPresenceSubscription = null;
     _matrixRoomIdForThisChat = null;
    chatStream.dispose();
    matrixSubscription = null;
  }

  @internal
  Future<Channel> getChannel() async {
    return await coreSDK.getChannelByOtherPartyPermanentDid(otherPartyDid) ??
        (throw Exception(
          'Channel with other party DID ${otherPartyDid.topAndTail()} not found',
        ));
  }

  /// Sends a message with notification, ignoring notification failures.
  Future<void> _sendMessageWithNotification(
    PlainTextMessage message, {
    List<String>? mentionUserIds,
  }) async {
    try {
      await sendPlainTextMessage(
        message,
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
        notify: true,
        mentionUserIds: mentionUserIds,
      );
    } on MeetingPlaceCoreSDKException catch (e) {
      final isNotificationError =
          e.code ==
          MeetingPlaceCoreSDKErrorCode.channelNotificationFailed.value;

      if (!isNotificationError) {
        _logger.error(
          'Failed to send message with notification',
          error: e,
          name: '_sendMessageWithNotification',
        );
        rethrow;
      }

      _logger.warning(
        'Failed to send notification for message ${message.id}',
        name: '_sendMessageWithNotification',
      );
    }
  }

  Future<Message> _updateMessageStatus({
    required String chatId,
    required String messageId,
  }) async {
    // TODO: add optimistic locking
    final message = await chatRepository.getMessage(
      chatId: chatId,
      messageId: messageId,
    );

    if (message!.status == ChatItemStatus.queued) {
      message.status = ChatItemStatus.sent;
      await chatRepository.updateMesssage(message);
    }

    return message as Message;
  }

  Future<Message> _handleSendMessageError({
    required ChatItem createdMessage,
    required PlainTextMessage chatMessage,
    required Object error,
    required StackTrace stackTrace,
    required String methodName,
  }) async {
    createdMessage.status = ChatItemStatus.error;
    await chatRepository.updateMesssage(createdMessage);

    _logger.error(
      'Failed to send message',
      error: error,
      stackTrace: stackTrace,
      name: methodName,
    );

    chatStream.pushData(
      StreamData(plainTextMessage: chatMessage, chatItem: createdMessage),
    );

    return createdMessage as Message;
  }

  String _contactHash(ContactCard card) {
    return sha256.convert(utf8.encode(jsonEncode(card.contactInfo))).toString();
  }
}
