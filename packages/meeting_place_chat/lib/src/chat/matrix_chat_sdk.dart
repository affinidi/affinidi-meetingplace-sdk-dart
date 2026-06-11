import 'dart:async';
import 'dart:typed_data';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_chat.dart';
import '../event/chat_event_conversion.dart';
import '../transport/matrix/incoming/incoming_room_event_router.dart';
import '../transport/matrix/outgoing/outgoing.dart';
import 'base_chat_sdk.dart';

/// Intermediate [BaseChatSDK] that provides the Matrix transport.
///
/// Holds Matrix-only state (server↔message id maps and the room subscription)
/// and implements every Matrix-flavoured send and the room subscription/
/// history flow. `GroupMatrixChatSDK` and `IndividualMatrixChatSDK` extend
/// this; the DIDComm individual SDK does not.
abstract class MatrixChatSDK extends BaseChatSDK {
  MatrixChatSDK({
    required super.coreSDK,
    required super.did,
    required super.otherPartyDid,
    required super.mediatorDid,
    required super.chatRepository,
    required super.options,
    super.card,
    super.logger,
  });

  static const String _matrixLogkey = 'MatrixChatSDK';

  final Map<String, String> _serverEventIdToMessageId = {};
  final Map<String, String> _reactionServerEventIds = {};
  StreamSubscription<MatrixRoomEvent>? _matrixRoomSubscription;
  IncomingMessageHandle? _matrixSubscriptionHandle;
  late IncomingRoomEventRouter _incomingRouter = buildRoomEventRouter();

  @internal
  Map<String, String> get serverEventIdToMessageId => _serverEventIdToMessageId;

  /// Hook for subclasses to provide a specialized router.
  @protected
  IncomingRoomEventRouter buildRoomEventRouter() =>
      IncomingRoomEventRouter(chatSDK: this);

  /// Builds the control-plane channel notification attached to outgoing
  /// matrix events. Default: notify the single peer via their channel token.
  /// Group chats override to fan out via [GroupChannelNotification].
  @protected
  ChannelNotification buildChannelNotification(String type) =>
      IndividualChannelNotification(recipientDid: otherPartyDid, type: type);

  @override
  Future<Chat> startChatSession() async {
    chatStream = ChatStream();
    _incomingRouter = buildRoomEventRouter();

    // Kick off the live transport subscription. transportSubscriptionFuture
    // resolves when Matrix auth + room subscribe are ready, matching the
    // DIDComm SDK semantics and the BaseChatSDK.chatStreamSubscription
    // contract.
    final subscriptionFuture = subscribeToMatrixRoom();
    transportSubscriptionFuture = subscriptionFuture;

    unawaited(proposeProfileUpdate());

    // Return the locally persisted snapshot so the UI can render immediately.
    // Matrix auth, history fetch, and the read receipt run in the background;
    // any new items they produce flow into the UI through chatStream via the
    // incoming router's per-event handlers.
    final persisted = await chatRepository.listMessages(chatId);
    final chat = Chat(
      id: chatId,
      stream: chatStream,
      messages: <ChatItem>[...persisted],
    );

    unawaited(_bootstrapTransportInBackground(subscriptionFuture));

    logger.info(
      'Chat session started; transport sync running in background',
      name: _matrixLogkey,
    );

    return chat;
  }

  Future<void> _bootstrapTransportInBackground(
    Future<StreamSubscription<MatrixRoomEvent>> subscriptionFuture,
  ) async {
    try {
      final subscription = await subscriptionFuture;
      // end() nulls transportSubscriptionFuture via super.end(); use it as
      // the liveness flag so we don't write to a disposed stream after
      // the session was torn down while Matrix auth was in flight.
      if (transportSubscriptionFuture == null) {
        await subscription.cancel();
        return;
      }
      _matrixRoomSubscription = subscription;

      final events = await _fetchRoomHistoryAsRoomEvents();
      final incoming = events.where((e) => !e.isFromMe).toList();

      for (final event in incoming) {
        if (transportSubscriptionFuture == null) return;
        await _handleIncomingRoomEvent(event);
      }

      final latestReceiptId = _latestReceiptWorthyId(incoming);
      if (latestReceiptId != null && transportSubscriptionFuture != null) {
        await sendChatDeliveredMessage(latestReceiptId);
      }
    } catch (e, st) {
      logger.error(
        'Background Matrix sync failed',
        error: e,
        stackTrace: st,
        name: _matrixLogkey,
      );
    }
  }

  @override
  Future<List<ChatItem>> get messages async {
    logger.info('Retrieving all persisted messages', name: 'messages');
    return chatRepository.listMessages(chatId);
  }

  @internal
  Future<StreamSubscription<MatrixRoomEvent>> subscribeToMatrixRoom() async {
    final handle = await coreSDK.subscribe(
      MatrixRoomSubscription(
        receiverDid: did,
        options: const MatrixSubscriptionOptions(excludeSelf: true),
      ),
    );
    _matrixSubscriptionHandle = handle;
    return handle.stream
        .where((m) => m is MatrixIncomingMessage)
        .cast<MatrixIncomingMessage>()
        .map(_toRoomEvent)
        .listen((event) async {
          await _handleIncomingRoomEvent(event);
          if (_isReceiptWorthy(event)) {
            await sendChatDeliveredMessage(event.id);
          }
        });
  }

  Future<void> _handleIncomingRoomEvent(MatrixRoomEvent event) =>
      _incomingRouter.route(event);

  /// True when [event] is a primary `m.room.message` (i.e. not an edit).
  /// Used to decide whether to issue an `m.read` receipt — edits piggyback on
  /// the receipt for the original message.
  static bool _isReceiptWorthy(MatrixRoomEvent event) {
    if (event.type != 'm.room.message') return false;
    final relatesTo = event.content['m.relates_to'] as Map<String, dynamic>?;
    return relatesTo?['rel_type'] != 'm.replace';
  }

  /// Returns the id of the most recent receipt-worthy event in [events], or
  /// `null` if none qualify. History fetches are not guaranteed to be in
  /// chronological order, so we pick by timestamp rather than position.
  static String? _latestReceiptWorthyId(List<MatrixRoomEvent> events) {
    MatrixRoomEvent? latest;
    for (final event in events) {
      if (!_isReceiptWorthy(event)) continue;
      if (latest == null || event.timestamp.isAfter(latest.timestamp)) {
        latest = event;
      }
    }
    return latest?.id;
  }

  @override
  Future<Message> sendTextMessage(
    String text, {
    List<ChatAttachment> attachments = const [],
  }) async {
    assertCanSend();

    final Message message;
    if (attachments.isEmpty) {
      final outgoing = TextMessageRoomEvent(
        senderDid: did,
        text: text,
        notification: buildChannelNotification('chat-activity'),
      );
      message = await _sendRoomEventMessage(outgoing);
      logger.info(
        'Text message sent, message id: ${message.messageId}',
        name: _matrixLogkey,
      );
    } else {
      message = await MediaTextMessageSender(
        coreSDK: coreSDK,
        did: did,
        chatId: chatId,
        chatRepository: chatRepository,
        chatStream: chatStream,
        serverEventIdToMessageId: _serverEventIdToMessageId,
        getChannel: getChannel,
        logger: logger,
      ).send(text: text, attachments: attachments);
    }

    await coreSDK.sendMessage(
      ChatTypingNotification(senderDid: did, active: false),
    );
    return message;
  }

  @override
  Future<Uint8List> downloadMedia(ChatAttachment attachment) async {
    final eventId = attachment.transportId;
    if (eventId == null) {
      throw StateError(
        'Attachment has no transportId; cannot download hosted media',
      );
    }
    final channel = await getChannel();
    return coreSDK.downloadMedia(channel, MatrixEventMediaReference(eventId));
  }

  /// Sends an `m.read` receipt for [messageId], marking it as delivered.
  @override
  Future<void> sendChatDeliveredMessage(String messageId) async {
    assertCanSend();
    await coreSDK.sendMessage(
      ReadReceiptRoomEvent(senderDid: did, eventId: messageId),
    );
  }

  @override
  Future<void> reactOnMessage(
    Message message, {
    required String reaction,
  }) async {
    assertCanSend();
    final methodName = 'reactOnMessage';
    logger.info('Started reacting on message', name: methodName);

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
            RedactionRoomEvent(senderDid: did, targetEventId: reactionEventId),
          );
          _reactionServerEventIds.remove(reactionKey);
        }
      } else {
        final serverEventId = await coreSDK.sendMessage(
          ReactionRoomEvent(
            senderDid: did,
            targetEventId: message.transportId ?? message.messageId,
            reaction: reaction,
          ),
        );
        if (serverEventId != null) {
          _reactionServerEventIds[reactionKey] = serverEventId;
        }
      }
    } catch (e, stackTrace) {
      logger.error(
        'Failed to send reaction message',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      if (isRemoving) {
        message.reactions.add(reaction);
      } else {
        message.reactions.remove(reaction);
      }
      await chatRepository.updateMesssage(message);
      Error.throwWithStackTrace(e, stackTrace);
    }

    logger.info('Completed reacting on message', name: methodName);
  }

  @override
  Future<void> editTextMessage(Message message, String newText) async {
    assertCanSend();
    final methodName = 'editTextMessage';

    if (!message.isFromMe) {
      throw StateError('Only the original sender can edit a message');
    }
    final trimmed = newText.trim();
    if (trimmed.isEmpty) {
      throw StateError('Edited message text must not be empty');
    }
    if (trimmed == message.value) {
      throw StateError('Edited message text is unchanged');
    }
    final transportId = message.transportId;
    if (transportId == null) {
      throw StateError('Cannot edit a message that has not yet been delivered');
    }

    final previousValue = message.value;
    final previousEditedAt = message.editedAt;

    message.value = trimmed;
    message.editedAt = DateTime.now().toUtc();
    await chatRepository.updateMesssage(message);
    chatStream.pushData(StreamData(chatItem: message));

    try {
      await coreSDK.sendMessage(
        MessageEditRoomEvent(
          senderDid: did,
          targetEventId: transportId,
          newText: trimmed,
        ),
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to send message edit',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      message.value = previousValue;
      message.editedAt = previousEditedAt;
      await chatRepository.updateMesssage(message);
      chatStream.pushData(StreamData(chatItem: message));
      Error.throwWithStackTrace(e, stackTrace);
    }

    logger.info('Completed editing message', name: methodName);
  }

  @override
  Future<void> deleteMessage(Message message, {bool localOnly = false}) async {
    const methodName = 'deleteMessage';

    if (!message.isFromMe) {
      throw StateError('Only the original sender can delete a message');
    }

    if (localOnly) {
      if (message.isDeletedLocally) return;
      message.isDeletedLocally = true;
      message.clearContent();
      await chatRepository.updateMesssage(message);
      chatStream.pushData(StreamData(chatItem: message));
      logger.info(
        'Hid message locally: ${message.messageId}',
        name: methodName,
      );
      return;
    }

    assertCanSend();
    final transportId = message.transportId;
    if (transportId == null) {
      throw StateError(
        'Cannot delete a message that has not yet been delivered',
      );
    }
    if (message.isDeleted) return;

    final window = options.deleteMessageWindow;
    final age = DateTime.now().toUtc().difference(message.dateCreated);
    if (window == Duration.zero || age > window) {
      throw StateError('Window for deleting this message has expired');
    }

    final previousValue = message.value;
    final previousAttachments = List<ChatAttachment>.from(message.attachments);
    final previousReactions = List<String>.from(message.reactions);
    final previousEditedAt = message.editedAt;

    message.isDeleted = true;
    message.clearContent();
    await chatRepository.updateMesssage(message);
    chatStream.pushData(StreamData(chatItem: message));

    try {
      await coreSDK.sendMessage(
        RedactionRoomEvent(senderDid: did, targetEventId: transportId),
      );
      logger.info('Deleted message: ${message.messageId}', name: methodName);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to send message redaction',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      message.isDeleted = false;
      message.value = previousValue;
      message.attachments = previousAttachments;
      message.reactions = previousReactions;
      message.editedAt = previousEditedAt;
      await chatRepository.updateMesssage(message);
      chatStream.pushData(StreamData(chatItem: message));
      Error.throwWithStackTrace(e, stackTrace);
    }
  }

  /// Dispatches an arbitrary Matrix room event into the underlying room.
  ///
  /// Low-level escape hatch: the SDK does not persist a [ChatItem] or push to
  /// [chatStream] for the sender. Receivers handle the event through their
  /// existing incoming routers based on [type].
  Future<void> sendCustomEvent({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    assertCanSend();
    await coreSDK.sendMessage(
      MatrixCustomOutgoingMessage(senderDid: did, type: type, content: payload),
    );

    logger.info('Sent custom room event of type $type', name: _matrixLogkey);
  }

  @override
  Future<void> sendEffect(Effect effect) async {
    assertCanSend();
    final roomEvent = EffectRoomEvent(senderDid: did, effect: effect.name);

    chatStream.pushData(StreamData(event: roomEvent.toChatEvent()));

    await coreSDK.sendMessage(roomEvent);
    logger.info('Chat effect sent', name: _matrixLogkey);
  }

  /// Sends a typing indicator (`m.typing`) for the configured activity
  /// expiry. Both group and individual Matrix chats share this impl.
  @override
  Future<void> sendChatActivity() async {
    assertCanSend();
    await coreSDK.sendMessage(
      ChatTypingNotification(
        senderDid: did,
        active: true,
        timeoutMs: options.chatActivityExpiry.inMilliseconds,
      ),
    );
    logger.info('Sent chat activity', name: _matrixLogkey);
  }

  /// Matrix has no presence primitive on this branch, so the Matrix transport
  /// silently swallows presence ticks. The presence loop keeps running so
  /// future transports can hook in without changing the lifecycle.
  @override
  Future<void> sendChatPresence() async {
    logger.info(
      'sendChatPresence: no-op (Matrix has no presence primitive)',
      name: _matrixLogkey,
    );
  }

  /// Broadcasts updated contact details as a Matrix room event and confirms
  /// the originating concierge message. Subclasses with additional state
  /// (e.g. [GroupMatrixChatSDK]) override and call `super` after their own
  /// bookkeeping.
  @override
  Future<void> sendChatContactDetailsUpdate(ConciergeMessage message) async {
    assertCanSend();
    final c = card;
    if (c == null) {
      throw StateError('ContactCard missing for contact details update');
    }

    unawaited(
      coreSDK.sendMessage(
        ContactDetailsUpdateRoomEvent(
          senderDid: did,
          profileDetails: c.toJson(),
        ),
      ),
    );

    message.status = ChatItemStatus.confirmed;
    await chatRepository.updateMesssage(message);
    chatStream.pushData(StreamData(chatItem: message));

    logger.info('Sent chat contact details update', name: _matrixLogkey);
  }

  @override
  Future<void> end() async {
    await _matrixRoomSubscription?.cancel();
    _matrixRoomSubscription = null;
    await _matrixSubscriptionHandle?.dispose();
    _matrixSubscriptionHandle = null;
    await super.end();
  }

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
      ),
    );

    try {
      chatStream.pushData(
        StreamData(event: outgoing.toChatEvent(), chatItem: createdMessage),
      );

      final serverEventId = await _sendMessageWithNotification(outgoing);

      if (serverEventId != null) {
        _serverEventIdToMessageId[serverEventId] = createdMessage.messageId;
        (createdMessage as Message).transportId = serverEventId;
        await chatRepository.updateMesssage(createdMessage);
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
        methodName: _matrixLogkey,
      );
    }
  }

  Future<String?> _sendMessageWithNotification(
    MatrixOutgoingMessage outgoing,
  ) async {
    try {
      return await coreSDK.sendMessage(outgoing);
    } on MeetingPlaceCoreSDKException catch (e) {
      final isNotificationError =
          e.code ==
          MeetingPlaceCoreSDKErrorCode.channelNotificationFailed.value;

      if (!isNotificationError) {
        logger.error(
          'Failed to send message with notification',
          error: e,
          name: '_sendMessageWithNotification',
        );
        rethrow;
      }

      logger.warning(
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

    logger.error(
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

  Future<List<MatrixRoomEvent>> _fetchRoomHistoryAsRoomEvents() async {
    final persisted = await chatRepository.listMessages(chatId);
    final latestTransportId = persisted
        .whereType<Message>()
        .where((m) => m.transportId != null)
        .fold<Message?>(null, (latest, m) {
          if (latest == null) return m;
          return m.dateCreated.isAfter(latest.dateCreated) ? m : latest;
        })
        ?.transportId;

    final incoming = await coreSDK.fetchHistory(
      MatrixRoomHistoryQuery(receiverDid: did, sinceEventId: latestTransportId),
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
      senderDid: m.senderDid,
      roomId: m.roomId,
      content: m.content,
      timestamp: m.timestamp,
      isFromMe: m.isFromMe,
      stateKey: m.stateKey,
    );
  }
}
