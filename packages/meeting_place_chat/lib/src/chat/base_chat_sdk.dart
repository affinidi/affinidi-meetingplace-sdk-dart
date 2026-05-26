import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_chat.dart';
import '../event/chat_event_conversion.dart';
import '../transport/matrix/matrix_user_id_cache.dart';
import '../transport/matrix/outgoing/outgoing.dart';
import '../transport/didcomm/outgoing/outgoing.dart';
import '../loggers/logger_formatter.dart';
import '../loggers/top_and_tail_extension.dart';
import '../transport/matrix/incoming/incoming_room_event_router.dart';

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
    required this.roomId,
    this.card,
    MeetingPlaceChatSDKLogger? logger,
  }) : chatStream = ChatStream(),
       _logger = LoggerFormatter(className: _className, baseLogger: logger),
       didCache = MatrixUserIdCache(serverName: roomId.split(':').last);

  static const String _className = 'BaseChatSDK';
  static const String _logkey = 'BaseChatSDK';

  final MeetingPlaceCoreSDK coreSDK;
  final String did;
  final String otherPartyDid;
  final String mediatorDid;
  final String roomId;
  final ChatRepository chatRepository;
  final ChatSDKOptions options;
  final ContactCard? card;
  final MeetingPlaceChatSDKLogger _logger;

  MeetingPlaceChatSDKLogger get logger => _logger;

  ChatStream chatStream;
  StreamSubscription<MatrixRoomEvent>? _matrixRoomSubscription;
  Future<StreamSubscription<MatrixRoomEvent>>? _subscriptionFuture;
  final Map<String, String> _serverEventIdToMessageId = {};
  final Map<String, String> _reactionServerEventIds = {};
  // Maps Matrix user ID → DID, populated by subclasses for known participants.
  @internal
  final MatrixUserIdCache didCache;
  late final IncomingRoomEventRouter _incomingRouter = buildRoomEventRouter();

  /// Hook for subclasses to provide a specialized router.
  @protected
  IncomingRoomEventRouter buildRoomEventRouter() =>
      IncomingRoomEventRouter(chatSDK: this);

  @internal
  Map<String, String> get serverEventIdToMessageId => _serverEventIdToMessageId;

  /// Unique chat ID derived from [did] and [otherPartyDid].
  String get chatId =>
      Chat.deriveId(did: did, otherPartyDid: otherPartyDid);

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
    chatStream = ChatStream();

    _subscriptionFuture = subscribeToMatrixRoom();

    unawaited(proposeProfileUpdate());

    final channel = await getChannel();

    final allEvents = await _fetchRoomHistoryAsRoomEvents();

    // TODO: Handle this in CoreSDK
    final syncMarker = channel.matrixSyncMarker;
    final events = syncMarker == null
        ? allEvents
        : allEvents.takeWhile((e) => e.id != syncMarker).toList();
    final incomingEvents = events.where((e) => !e.isFromMe).toList();

    // TODO: Update matrix sync marker in CoreSDK
    if (events.isNotEmpty) {
      channel.matrixSyncMarker = events.first.id;
      await coreSDK.updateChannel(channel);
    }

    final newMessages = <Message>[];
    for (final event in incomingEvents) {
      await _handleIncomingRoomEvent(event);
    }

    final existingMessages = await chatRepository.listMessages(chatId);
    final messages = <ChatItem>[...newMessages, ...existingMessages];

    final chat = Chat(id: chatId, stream: chatStream, messages: messages);

    unawaited(
      _subscriptionFuture!.then((subscription) {
        _matrixRoomSubscription = subscription;
      }),
    );

    // TODO: sort messages??
    _logger.info('Chat session initialized,', name: _logkey);

    return chat;
  }

  /// Waits until the mediator channel subscription is ready. Stream of live
  /// chat events ([StreamData]) for this session.
  ///
  /// **Returns:**
  /// - A [ChatStream] or `null` if the chat session has not yet started
  ///   or resumed.
  Future<ChatStream?> get chatStreamSubscription async {
    if (_subscriptionFuture == null) return null;
    await _subscriptionFuture;
    return chatStream;
  }

  /// Retrieves all messages for this chat from the Matrix client database.
  Future<List<ChatItem>> get messages async {
    final methodName = 'messages';
    _logger.info('Retrieving all persisted messages', name: methodName);
    final events = await _fetchRoomHistoryAsRoomEvents();
    return events
        .map((e) {
          final senderDid = _resolveSenderDIDFromRoomEvent(e);
          if (senderDid == null) {
            _logger.warning(
              'Could not resolve sender DID for event ${e.id}, skipping event.',
              name: methodName,
            );
            return null;
          }

          return e.isFromMe
              ? Message.fromRoomEventSentByMe(
                  event: e,
                  chatId: chatId,
                  senderDid: senderDid,
                )
              : Message.fromRoomEventReceivedByMe(
                  event: e,
                  chatId: chatId,
                  senderDid: senderDid,
                );
        })
        .toList()
        .whereType<ChatItem>()
        .toList();
  }

  /// Retrieves a single message by ID.
  ///
  /// **Parameters:**
  /// - [messageId]: Unique message identifier.
  ///
  /// **Returns:**
  /// - A [ChatItem] if found, or `null`.
  Future<ChatItem?> getMessageById(String messageId) {
    _logger.info('Retrieving message by ID: $messageId', name: _logkey);
    return chatRepository.getMessage(chatId: chatId, messageId: messageId);
  }

  /// Stream of live chat events ([StreamData]) for this session.
  ///
  /// **Throws:**
  /// - [Exception] if the chat has not been started first.
  Stream<StreamData> get stream {
    _logger.info('Returning chat event stream...', name: _logkey);
    return chatStream.stream;
  }

  @internal
  Future<StreamSubscription<MatrixRoomEvent>> subscribeToMatrixRoom() async {
    final stream = await coreSDK.subscribe(
      MatrixRoomSubscription(
        receiverDid: did,
        roomId: roomId,
        options: const MatrixSubscriptionOptions(excludeSelf: true),
      ),
    );
    return stream
        .where((m) => m is MatrixIncomingMessage)
        .cast<MatrixIncomingMessage>()
        .map(_toRoomEvent)
        .listen(_handleIncomingRoomEvent);
  }

  Future<void> _handleIncomingRoomEvent(MatrixRoomEvent event) =>
      _incomingRouter.route(event);

  /// Sends a plain text message with optional attachments.
  ///
  /// **Parameters:**
  /// - [text]: The plain text content of the message.
  /// - [attachments]: Optional list of [ChatAttachment]s included with
  ///   the message.
  ///
  /// **Returns:**
  /// - The sent [Message] object persisted in the repository.
  ///
  /// TODO: Add attachments support
  Future<Message> sendTextMessage(
    String text, {
    List<ChatAttachment>? attachments,
  }) async {
    final message = await _sendRoomEventMessage(
      TextMessageRoomEvent(senderDid: did, roomId: roomId, text: text),
    );

    _logger.info(
      'Text message sent, message id: ${message.messageId}',
      name: _logkey,
    );

    await coreSDK.sendMessage(
      ChatTypingNotification(
        senderDid: did,
        roomId: roomId,
        active: false,
      ),
    );
    return message;
  }

  /// Starts periodic chat presence updates.
  Future<void> startChatPresenceUpdates() async {}

  /// Sends a chat presence signal to the other party.
  Future<void> sendChatPresence() async {
    await coreSDK.sendMessage(
      ChatPresenceMessage(
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
        forwardExpiry: options.chatPresenceExpiry,
      ),
    );
  }

  /// Triggers a profile update proposal if the local contact card differs from
  /// the persisted channel card.
  Future<void> proposeProfileUpdate();

  /// Sends an `m.read` receipt for [messageId], marking it as delivered.
  ///
  /// In the Matrix path the [messageId] is the Matrix event ID, so this maps
  /// directly to the native read-marker API.
  Future<void> sendChatDeliveredMessage(String messageId) async {
    await coreSDK.sendMessage(
      ReadReceiptRoomEvent(senderDid: did, roomId: roomId, eventId: messageId),
    );
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
      coreSDK.sendMessage(
        ChatContactDetailsUpdateMessage(
          senderDid: did,
          recipientDid: otherPartyDid,
          mediatorDid: mediatorDid,
          profileDetails: card!.toJson(),
        ),
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
    _logger.info('Started reacting on message', name: methodName);

    final isRemoving = message.reactions.contains(reaction);

    if (isRemoving) {
      message.reactions.remove(reaction);
    } else {
      message.reactions.add(reaction);
    }

    await chatRepository.updateMesssage(message);

    final reactionKey = '${message.messageId}:$reaction';

    try {
      if (isRemoving) {
        final reactionEventId = _reactionServerEventIds[reactionKey];
        if (reactionEventId != null) {
          await coreSDK.sendMessage(
            RedactionRoomEvent(
              senderDid: did,
              roomId: roomId,
              targetEventId: reactionEventId,
            ),
          );
          _reactionServerEventIds.remove(reactionKey);
        }
      } else {
        final serverEventId = await coreSDK.sendMessage(
          ReactionRoomEvent(
            senderDid: did,
            roomId: roomId,
            targetEventId: message.messageId,
            reaction: reaction,
          ),
        );
        if (serverEventId != null) {
          _reactionServerEventIds[reactionKey] = serverEventId;
        }
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to send reaction message',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      // rollback
      if (isRemoving) {
        message.reactions.add(reaction);
      } else {
        message.reactions.remove(reaction);
      }
      await chatRepository.updateMesssage(message);
      Error.throwWithStackTrace(e, stackTrace);
    }

    _logger.info('Completed reacting on message', name: methodName);
  }

  /// Sends a chat effect (visual/animated signal).
  Future<void> sendEffect(Effect effect) async {
    final roomEvent = EffectRoomEvent(
      senderDid: did,
      roomId: roomId,
      effect: effect.name,
    );

    chatStream.pushData(StreamData(event: roomEvent.toChatEvent()));

    // TODO: handle error case
    await coreSDK.sendMessage(roomEvent);
    _logger.info('Chat effect sent', name: _logkey);
  }

  /// Sends a chat activity message.
  Future<void> sendChatActivity() async {
    final methodName = 'sendChatActivity';
    _logger.info('Started sending chat activity', name: methodName);
    await coreSDK.sendMessage(
      ChatActivityMessage(
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
        forwardExpiry: options.chatActivityExpiry,
      ),
    );
    _logger.info('Completed sending chat activity', name: methodName);
  }

  String? _resolveDid(String matrixUserId) => didCache.resolve(matrixUserId);

  /// Ends the chat session, disposing of the channel and stream manager.
  Future<void> end() async {
    await _matrixRoomSubscription?.cancel();
    _matrixRoomSubscription = null;
    _subscriptionFuture = null;
    chatStream.dispose();
  }

  @internal
  Future<Channel> getChannel() async {
    return await coreSDK.getChannelByOtherPartyPermanentDid(otherPartyDid) ??
        (throw Exception(
          'Channel with other party DID ${otherPartyDid.topAndTail()} not '
          'found',
        ));
  }

  // TODO: check if sequence number is still needed for badge count
  Future<Message> _sendRoomEventMessage(MatrixOutgoingMessage outgoing) async {
    final channel = await getChannel();
    channel.increaseSeqNo();

    final messageId = const Uuid().v4();
    final timestamp = DateTime.now().toUtc();

    final createdMessage = await chatRepository.createMessage(
      Message(
        chatId: chatId,
        messageId: messageId,
        senderDid: did,
        value: outgoing.content['body'] as String? ?? '',
        isFromMe: true,
        dateCreated: timestamp,
        status: ChatItemStatus.sent,
        attachments: const [],
      ),
    );

    try {
      chatStream.pushData(
        StreamData(event: outgoing.toChatEvent(), chatItem: createdMessage),
      );

      final serverEventId = await _sendMessageWithNotification(outgoing);

      if (serverEventId != null) {
        _serverEventIdToMessageId[serverEventId] = createdMessage.messageId;
      }

      final updatedMessage = await _updateMessageStatus(
        chatId: chatId,
        messageId: createdMessage.messageId,
      );

      await coreSDK.updateChannel(channel);

      chatStream.pushData(
        StreamData(event: outgoing.toChatEvent(), chatItem: updatedMessage),
      );

      return updatedMessage;
    } catch (e, stackTrace) {
      return _handleSendMessageError(
        createdMessage: createdMessage,
        outgoing: outgoing,
        error: e,
        stackTrace: stackTrace,
        methodName: _logkey,
      );
    }
  }

  /// Sends a message with notification, ignoring notification failures.
  /// Returns the server-assigned Matrix event ID, or `null` for receipt events.
  Future<String?> _sendMessageWithNotification(
    MatrixOutgoingMessage outgoing,
  ) async {
    try {
      // TODO: How to notify?
      return await coreSDK.sendMessage(outgoing);
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
        'Failed to send notification for message ${outgoing.type}',
        name: '_sendMessageWithNotification',
      );
      return null;
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
    required MatrixOutgoingMessage outgoing,
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
      StreamData(event: outgoing.toChatEvent(), chatItem: createdMessage),
    );

    return createdMessage as Message;
  }

  String? _resolveSenderDIDFromRoomEvent(MatrixRoomEvent e) {
    return _resolveDid(e.userId);
  }

  Future<List<MatrixRoomEvent>> _fetchRoomHistoryAsRoomEvents() async {
    final incoming = await coreSDK.fetchHistory(
      MatrixRoomHistoryQuery(receiverDid: did, roomId: roomId),
    );
    return incoming
        .whereType<MatrixIncomingMessage>()
        .map(_toRoomEvent)
        .toList();
  }

  MatrixRoomEvent _toRoomEvent(MatrixIncomingMessage m) {
    return MatrixRoomEvent(
      id: m.eventId,
      type: m.type,
      userId: m.senderDid,
      roomId: m.roomId,
      content: m.content,
      timestamp: m.timestamp,
      isFromMe: m.isFromMe,
    );
  }
}
