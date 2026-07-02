import 'dart:async';
import 'dart:typed_data';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_matrix.dart';
import '../constants.dart';
import '../event/chat_event_conversion.dart';
import '../transport/matrix/incoming/incoming_room_event_router.dart';
import '../transport/matrix/outgoing/outgoing.dart';
import 'typing_indicator_manager.dart';

/// Intermediate [BaseChatSDK] that provides the Matrix transport.
///
/// Holds Matrix-only state (server↔message id maps and the room subscription)
/// and implements every Matrix-flavoured send and the room subscription/
/// history flow. `GroupMatrixChatSDK` and `IndividualMatrixChatSDK` extend
/// this; the DIDComm individual SDK does not.
abstract class MeetingPlaceMatrixChatSDK extends BaseChatSDK
    implements MeetingPlaceChatSDK {
  MeetingPlaceMatrixChatSDK({
    required super.coreSDK,
    required super.did,
    required super.otherPartyDid,
    required super.mediatorDid,
    required super.chatRepository,
    required super.options,
    super.card,
    MeetingPlaceMatrixSDKLogger? logger,
  }) : _logger =
           logger ??
           DefaultMeetingPlaceMatrixSDKLogger(
             className: 'MatrixChatSDK',
             sdkName: sdkName,
           );

  static const String _matrixLogkey = 'MatrixChatSDK';

  final Map<String, String> _serverEventIdToMessageId = {};
  final Map<String, String> _reactionServerEventIds = {};
  final MeetingPlaceMatrixSDKLogger _logger;
  StreamSubscription<MatrixRoomEvent>? _matrixRoomSubscription;
  IncomingMessageHandle? _matrixSubscriptionHandle;

  late IncomingRoomEventRouter _incomingRouter = buildRoomEventRouter();

  late final _typingManager = TypingIndicatorManager(
    onSetTypingState: setTypingState,
    expiry: options.chatActivityExpiry,
    logger: _logger,
  );

  @internal
  Map<String, String> get serverEventIdToMessageId => _serverEventIdToMessageId;

  static Future<MeetingPlaceMatrixChatSDK> initialiseFromChannel(
    Channel channel, {
    required MeetingPlaceCoreSDK coreSDK,
    required ChatRepository chatRepository,
    required MeetingPlaceChatSDKOptions options,
    ContactCard? card,
    MeetingPlaceMatrixSDKLogger? logger,
  }) async {
    if (channel.transport != ChannelTransport.matrix) {
      throw ArgumentError(
        '''Transport ${channel.transport} is not supported by meeting_place_matrix.''',
      );
    }

    if (channel.type == ChannelType.group) {
      final group =
          await coreSDK.getGroupByOfferLink(channel.offerLink) ??
          (throw Exception('Group not found'));

      return GroupMatrixChatSDK(
        coreSDK: coreSDK,
        group: group,
        did: channel.permanentChannelDid!,
        otherPartyDid: channel.otherPartyPermanentChannelDid!,
        mediatorDid: channel.mediatorDid,
        chatRepository: chatRepository,
        options: options,
        card: card,
        logger: logger,
      );
    }

    return IndividualMatrixChatSDK(
      coreSDK: coreSDK,
      did: channel.permanentChannelDid!,
      otherPartyDid: channel.otherPartyPermanentChannelDid!,
      mediatorDid: channel.mediatorDid,
      chatRepository: chatRepository,
      options: options,
      card: card,
      logger: logger,
    );
  }

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

    // Snapshot the sync cursor before the live subscription starts.
    // Once subscribeToMatrixRoom() is awaited, newly-arriving Matrix events
    // can advance chatRepository's sync marker; reading it here guarantees
    // the bootstrap sees every event that arrived between the previous session
    // and this one (including m.room.member join events from members who joined
    // while the chat was closed).
    final bootstrapCursor = await chatRepository.getSyncMarker(chatId);

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

    unawaited(
      _bootstrapTransportInBackground(subscriptionFuture, bootstrapCursor),
    );

    logger.info(
      'Chat session started; transport sync running in background',
      name: _matrixLogkey,
    );

    return chat;
  }

  Future<void> _bootstrapTransportInBackground(
    Future<StreamSubscription<MatrixRoomEvent>> subscriptionFuture,
    String? bootstrapCursor,
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

      final events = await _fetchRoomHistoryAsRoomEvents(bootstrapCursor);
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
        options: const TransportSubscriptionOptions(excludeSelf: true),
      ),
    );
    _matrixSubscriptionHandle = handle;
    return handle.stream
        .where((m) => m is MatrixIncomingMessage)
        .cast<MatrixIncomingMessage>()
        .map(_toRoomEvent)
        .listen((event) async {
          await _handleIncomingRoomEvent(event);
          await _advanceSyncMarker(event);
          if (_isReceiptWorthy(event)) {
            await sendChatDeliveredMessage(event.id);
          }
        });
  }

  Future<void> _handleIncomingRoomEvent(MatrixRoomEvent event) =>
      _incomingRouter.route(event);

  // m.typing events carry a synthetic local ID that is never persisted on the
  // server; storing it as the sync marker causes M_NOT_FOUND on the next
  // bootstrap's getEventContext call.
  Future<void> _advanceSyncMarker(MatrixRoomEvent event) async {
    if (event.type == 'm.typing') return;
    await chatRepository.updateSyncMarker(chatId: chatId, eventId: event.id);
  }

  /// True when [event] is a primary `m.room.message` (i.e. not an edit) or a
  /// `mpx.call.item`. Used to decide whether to issue an `m.read` receipt —
  /// edits piggyback on the receipt for the original message.
  static bool _isReceiptWorthy(MatrixRoomEvent event) {
    if (event.type == MpxCallEventType.callItem) return true;
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
    final notification = buildChannelNotification('chat-activity');
    if (attachments.isEmpty) {
      final outgoing = TextMessageRoomEvent(
        senderDid: did,
        text: text,
        notification: notification,
      );
      message = await _sendRoomEventMessage(outgoing);
      logger.info(
        'Text message sent, message id: ${message.messageId}',
        name: _matrixLogkey,
      );
    } else if (attachments.every((a) => a.data == null && a.metadata != null)) {
      final outgoing = CallItemRoomEvent(
        senderDid: did,
        metadata: attachments.first.metadata ?? {},
        notification: notification,
      );
      message = await _sendRoomEventMessage(outgoing, attachments: attachments);
      logger.info(
        'Metadata-only message sent, message id: ${message.messageId}',
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
      ).send(text: text, attachments: attachments, notification: notification);
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

    // Toggle only the local user's own reaction. A reaction carrying the same
    // emoji from a different participant is independent and must not be
    // touched — otherwise reacting with an emoji already present (from someone
    // else) would be misread as undoing it.
    final mine = MessageReaction(emoji: reaction, senderDid: did);
    final isRemoving = message.reactions.contains(mine);

    if (isRemoving) {
      message.reactions.remove(mine);
    } else {
      message.reactions.add(mine);
    }

    await chatRepository.updateMesssage(message);
    // Surface the optimistic change immediately so the local user sees their
    // own add/undo without waiting for a server echo (own events are filtered
    // from the incoming stream).
    chatStream.pushData(StreamData(chatItem: message));

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
        message.reactions.add(mine);
      } else {
        message.reactions.remove(mine);
      }
      await chatRepository.updateMesssage(message);
      chatStream.pushData(StreamData(chatItem: message));
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
    final previousReactions = List<MessageReaction>.from(message.reactions);
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

  @override
  Future<void> updateMessage(Message message) async {
    await chatRepository.updateMesssage(message);
    chatStream.pushData(
      StreamData(event: const ChatMessageUpdatedEvent(), chatItem: message),
    );
    logger.info('updateMessage: ${message.messageId}', name: _matrixLogkey);
  }

  /// Dispatches an arbitrary Matrix room event into the underlying room.
  ///
  /// Low-level escape hatch: the SDK does not persist a [ChatItem] or push to
  /// [chatStream] for the sender. Receivers handle the event through their
  /// existing incoming routers based on [type].
  @override
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

  /// Sends a typing indicator (`m.typing`) for the configured activity expiry.
  /// The indicator is cleared automatically after
  /// [MeetingPlaceChatSDKOptions.chatActivityExpiry] elapses without a new
  /// call.
  @override
  Future<void> sendChatActivity() async {
    assertCanSend();
    await _typingManager.sendActivity();
  }

  Future<void> setTypingState(bool active) async {
    await coreSDK.sendMessage(
      ChatTypingNotification(
        senderDid: did,
        active: active,
        timeoutMs: options.chatActivityExpiry.inMilliseconds,
      ),
    );
    logger.info('Sent chat activity (active=$active)', name: _matrixLogkey);
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
      ContactDetailsUpdateSender(
        coreSDK: coreSDK,
        getChannel: getChannel,
      ).send(senderDid: did, contactCard: c),
    );

    message.status = ChatItemStatus.confirmed;
    await chatRepository.updateMesssage(message);
    chatStream.pushData(StreamData(chatItem: message));

    logger.info('Sent chat contact details update', name: _matrixLogkey);
  }

  @override
  Future<void> end() async {
    _typingManager.stop();
    await _matrixSubscriptionHandle?.dispose();
    _matrixSubscriptionHandle = null;
    // cancel() propagates to the Matrix long-poll and may never resolve if
    // the SDK waits for the in-flight HTTP request to complete. Fire and
    // forget: the subscription stops delivering events immediately.
    unawaited(_matrixRoomSubscription?.cancel());
    _matrixRoomSubscription = null;
    await super.end();
  }

  Future<Message> _sendRoomEventMessage(
    MatrixOutgoingMessage outgoing, {
    List<ChatAttachment> attachments = const [],
  }) async {
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
        attachments: attachments,
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

  Future<List<MatrixRoomEvent>> _fetchRoomHistoryAsRoomEvents(
    String? bootstrapCursor,
  ) async {
    final historyEvents = await coreSDK.fetchHistory(
      MatrixRoomHistoryQuery(
        receiverDid: did,
        since: bootstrapCursor,
        updateChannelSyncMarker: false,
      ),
    );

    final events = historyEvents
        .whereType<MatrixIncomingMessage>()
        .map((m) => _toRoomEvent(m, isReplay: true))
        .toList();

    if (events.isNotEmpty) {
      final currentMarker = await chatRepository.getSyncMarker(chatId);
      if (currentMarker == bootstrapCursor) {
        await chatRepository.updateSyncMarker(
          chatId: chatId,
          eventId: events.last.id,
        );
      }
    }

    return events.reversed.toList();
  }

  MatrixRoomEvent _toRoomEvent(
    MatrixIncomingMessage m, {
    bool isReplay = false,
  }) {
    return MatrixRoomEvent(
      id: m.eventId,
      type: m.type,
      senderDid: m.senderDid,
      roomId: m.roomId,
      content: m.content,
      timestamp: m.timestamp,
      isFromMe: m.isFromMe,
      isReplay: isReplay,
      stateKey: m.stateKey,
    );
  }
}
