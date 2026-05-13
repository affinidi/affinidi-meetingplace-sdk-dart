import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_chat.dart';
import '../core/chat_stream/chat_event_conversion.dart';
import '../core/matrix_user_id_cache.dart';
import '../core/room_event/room_event.dart';
import '../loggers/logger_formatter.dart';
import '../protocol/protocol.dart' as protocol;
import '../utils/chat_utils.dart';
import '../utils/top_and_tail_extension.dart';
import 'custom_room_event.dart';
import 'incoming_room_event_router.dart';

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

  /// Sends a direct plain text message to another party.
  ///
  /// **Parameters:**
  /// - [message]: The `PlainTextMessage` to send.
  /// - [senderDid]: DID of the user who sent the message.
  /// - [recipientDid]: DID of the recipient of the message.
  /// - [mediatorDid]: DID of the mediator used for routing.
  /// - [notify]: Whether to notify via `"chat-activity"` channel
  /// (default: `false`).
  /// - [ephemeral]: Whether the message is ephemeral (default: `false`).
  /// - [forwardExpiryInSeconds]: Optional duration (in seconds) after which
  /// the forwarded message is considered expired.
  /// **Returns:**
  /// - A [Future] that completes when the message has been sent.
  Future<void> sendPlainTextMessage(
    PlainTextMessage message, {
    required String senderDid,
    required String recipientDid,
    required String mediatorDid,
    bool notify = false,
    bool ephemeral = false,
    int? forwardExpiryInSeconds,
  }) {
    return coreSDK.didcomm.sendMessage(
      message,
      senderDid: senderDid,
      recipientDid: recipientDid,
      mediatorDid: mediatorDid,
      notifyChannelType: notify ? 'chat-activity' : null,
      ephemeral: ephemeral,
      forwardExpiryInSeconds: forwardExpiryInSeconds,
    );
  }

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
    chatStream = ChatStream();

    _subscriptionFuture = subscribeToMatrixRoom();

    unawaited(proposeProfileUpdate());

    final channel = await getChannel();

    final allEvents = await coreSDK.matrix.fetchRoomHistory(
      roomId: roomId,
      receiverDid: did,
    );

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
    final events = await coreSDK.matrix.fetchRoomHistory(
      roomId: roomId,
      receiverDid: did,
    );
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
    return (await coreSDK.matrix.subscribeToRoom(
      roomId: roomId,
      receiverDid: did,
      options: const MatrixSubscriptionOptions(excludeSelf: true),
    )).listen(_handleIncomingRoomEvent);
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
      TextMessageRoomEvent.create(senderDid: did, roomId: roomId, text: text),
    );

    _logger.info(
      'Text message sent, message id: ${message.messageId}',
      name: _logkey,
    );

    await coreSDK.matrix.disableTyping(roomId: roomId, senderDid: did);
    return message;
  }

  /// Starts periodic chat presence updates.
  Future<void> startChatPresenceUpdates() async {}

  /// Sends a chat presence signal to the other party.
  Future<void> sendChatPresence() async {
    final message = protocol.ChatPresence.create(
      from: did,
      to: [otherPartyDid],
    );

    return sendPlainTextMessage(
      message.toPlainTextMessage(),
      senderDid: did,
      recipientDid: otherPartyDid,
      mediatorDid: mediatorDid,
      forwardExpiryInSeconds: options.chatPresenceExpiry.inSeconds,
    );
  }

  /// Triggers a profile update proposal if the local contact card differs from
  /// the persisted channel card.
  Future<void> proposeProfileUpdate();

  /// Sends an `m.read` receipt for [messageId], marking it as delivered.
  ///
  /// In the Matrix path the [messageId] is the Matrix event ID, so this maps
  /// directly to the native read-marker API.
  Future<void> sendChatDeliveredMessage(String messageId) {
    return coreSDK.matrix.sendRoomEvent(
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
          await coreSDK.matrix.sendRoomEvent(
            RedactionRoomEvent(
              senderDid: did,
              roomId: roomId,
              targetEventId: reactionEventId,
            ),
          );
          _reactionServerEventIds.remove(reactionKey);
        }
      } else {
        final serverEventId = await coreSDK.matrix.sendRoomEvent(
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
    await coreSDK.matrix.sendRoomEvent(roomEvent);
    _logger.info('Chat effect sent', name: _logkey);
  }

  /// Sends a chat activity message.
  Future<void> sendChatActivity() async {
    final methodName = 'sendChatActivity';
    _logger.info('Started sending chat activity', name: methodName);
    await sendPlainTextMessage(
      protocol.ChatActivity.create(
        from: did,
        to: [otherPartyDid],
      ).toPlainTextMessage(),
      senderDid: did,
      recipientDid: otherPartyDid,
      mediatorDid: mediatorDid,
      ephemeral: true,
      forwardExpiryInSeconds: options.chatActivityExpiry.inSeconds,
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
  Future<Message> _sendRoomEventMessage(MatrixRoomEvent roomEvent) async {
    final channel = await getChannel();
    channel.increaseSeqNo();

    final createdMessage = await chatRepository.createMessage(
      Message.fromRoomEventSentByMe(
        event: roomEvent,
        chatId: chatId,
        senderDid: did,
      ),
    );

    try {
      chatStream.pushData(
        StreamData(event: roomEvent.toChatEvent(), chatItem: createdMessage),
      );

      final serverEventId = await _sendMessageWithNotification(roomEvent);

      if (serverEventId != null) {
        _serverEventIdToMessageId[serverEventId] = createdMessage.messageId;
      }

      final updatedMessage = await _updateMessageStatus(
        chatId: chatId,
        messageId: createdMessage.messageId,
      );

      await coreSDK.updateChannel(channel);

      chatStream.pushData(
        StreamData(event: roomEvent.toChatEvent(), chatItem: updatedMessage),
      );

      return updatedMessage;
    } catch (e, stackTrace) {
      return _handleSendMessageError(
        createdMessage: createdMessage,
        event: roomEvent,
        error: e,
        stackTrace: stackTrace,
        methodName: _logkey,
      );
    }
  }

  /// Sends a message with notification, ignoring notification failures.
  /// Returns the server-assigned Matrix event ID, or `null` for receipt events.
  Future<String?> _sendMessageWithNotification(MatrixRoomEvent event) async {
    try {
      // TODO: How to notify?
      return await coreSDK.matrix.sendRoomEvent(event);
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
        'Failed to send notification for message ${event.id}',
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
    required MatrixRoomEvent event,
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
      StreamData(event: event.toChatEvent(), chatItem: createdMessage),
    );

    return createdMessage as Message;
  }

  String? _resolveSenderDIDFromRoomEvent(MatrixRoomEvent e) {
    return _resolveDid(e.userId);
  }
}
