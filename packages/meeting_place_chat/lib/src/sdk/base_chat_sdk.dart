import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';

import '../../meeting_place_chat.dart';
import '../core/chat_stream/chat_event_conversion.dart';
import '../core/room_event/room_event.dart';
import '../entity/chat_attachment_conversion.dart';
import '../handlers/chat_alias_profile_hash_handler.dart';
import '../handlers/chat_alias_profile_request_handler.dart';
import '../handlers/chat_contact_details_update_handler.dart';
import '../handlers/chat_delivered_handler.dart';
import '../handlers/chat_message_handler.dart';
import '../handlers/chat_reaction_handler.dart';
import '../loggers/logger_formatter.dart';
import '../protocol/protocol.dart' as protocol;
import '../utils/chat_utils.dart';
import '../utils/top_and_tail_extension.dart';

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
  }) : _logger = LoggerFormatter(className: _className, baseLogger: logger),
       chatStream = ChatStream();

  static const String _className = 'BaseChatSDK';
  static const String _logkey = 'BaseChatSDK';

  static const _streamOnlyTypes = {
    ChatProtocol.chatActivity,
    ChatProtocol.chatPresence,
    ChatProtocol.chatEffect,
  };

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
  // Maps incoming reaction server event ID → "$messageId:$reaction"
  final Map<String, String> _incomingReactionEventIds = {};
  int? seqNo;

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
    chatStream = ChatStream();

    _subscriptionFuture = subscribeToMatrixRoom();

    unawaited(sendProfileHash());

    final channel = await getChannel();
    final allEvents = await coreSDK.fetchMatrixRoomHistory(
      roomId: roomId,
      receiverDid: did,
    );

    // TODO: Handle this in CoreSDK
    final syncMarker = channel.matrixSyncMarker;
    final events = syncMarker == null
        ? allEvents
        : allEvents.takeWhile((e) => e.id != syncMarker).toList();

    // TODO: Update matrix sync marker in CoreSDK
    if (events.isNotEmpty) {
      channel.matrixSyncMarker = events.first.id;
      await coreSDK.updateChannel(channel);
    }

    final newMessages = <Message>[];
    for (final event in events) {
      final msg = await _handleIncomingRoomEvent(event);
      if (msg != null) newMessages.add(msg);
    }

    final existingMessages = allEvents
        .skip(events.length)
        .map(
          (e) => e.isFromMe
              ? Message.fromRoomEventSentByMe(event: e, chatId: chatId)
              : Message.fromRoomEventReceivedByMe(event: e, chatId: chatId),
        )
        .toList();

    final messages = [...newMessages, ...existingMessages];

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
    final events = await coreSDK.fetchMatrixRoomHistory(
      roomId: roomId,
      receiverDid: did,
    );
    return events
        .map(
          (e) => e.isFromMe
              ? Message.fromRoomEventSentByMe(event: e, chatId: chatId)
              : Message.fromRoomEventReceivedByMe(event: e, chatId: chatId),
        )
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

  /// Map of [ChatProtocol] to handler callbacks for message dispatch.
  Map<String, Future<void> Function(MediatorMessage, Channel)>
  get _messageHandlers => {
    ChatProtocol.chatMessage.value: (msg, _) => ChatMessageHandler(
      chatRepository: chatRepository,
      streamManager: chatStream,
    ).handle(message: msg, chatId: chatId),
    ChatProtocol.chatReaction.value: (msg, _) => ChatReactionHandler(
      chatRepository: chatRepository,
      streamManager: chatStream,
    ).handle(message: msg, chatId: chatId),
    ChatProtocol.chatAliasProfileHash.value: (msg, ch) async {
      if (ch.type != ChannelType.group) {
        await ChatAliasProfileHashHandler(
          chatSDK: this,
          streamManager: chatStream,
        ).handle(message: msg.plainTextMessage, channel: ch);
      }
    },
    ChatProtocol.chatAliasProfileRequest.value: (msg, ch) async {
      if (ch.type != ChannelType.group) {
        await ChatAliasProfileRequestHandler(
          chatRepository: chatRepository,
          streamManager: chatStream,
        ).handle(message: msg.plainTextMessage, chatId: chatId);
      }
    },
    ChatProtocol.chatDelivered.value: (msg, _) => ChatDeliveredHandler(
      chatRepository: chatRepository,
      streamManager: chatStream,
    ).handle(message: msg, chatId: chatId),
    ChatProtocol.chatContactDetailsUpdate.value: (msg, ch) async {
      if (ch.type != ChannelType.group) {
        await ChatContactDetailsUpdateHandler(
          coreSDK: coreSDK,
          streamManager: chatStream,
        ).handle(message: msg.plainTextMessage, channel: ch);
      }
    },
  };

  /// Handles an incoming [PlainTextMessage].
  ///
  /// Supported message types:
  /// - **Chat message**: Persisted and pushed downstream.
  /// - **Reaction**: Updates existing message reactions.
  /// - **AliasProfileHash / AliasProfileRequest**: Validates or creates
  ///   concierge messages.
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

    final channel = await getChannel();
    if (_requiresSequenceNumberUpdate(message.plainTextMessage)) {
      final messageSequenceNumber = message.messageSequenceNumber;
      if (messageSequenceNumber != null &&
          messageSequenceNumber > channel.seqNo) {
        channel.seqNo = messageSequenceNumber;
        seqNo = messageSequenceNumber;
        await coreSDK.updateChannel(channel);
      }
    }

    final messageType = message.plainTextMessage.type.toString();
    final handler = _messageHandlers[messageType];
    if (handler != null) {
      _logger.info('Handling $messageType message', name: methodName);
      await handler(message, channel);
      return true;
    }

    final streamOnlyProtocol = ChatProtocol.byValue(messageType);
    if (streamOnlyProtocol != null &&
        _streamOnlyTypes.contains(streamOnlyProtocol)) {
      _logger.info(
        'Handling ${streamOnlyProtocol.name} message',
        name: methodName,
      );
      chatStream.pushData(
        StreamData(event: message.plainTextMessage.toChatEvent()),
      );
      return true;
    }

    return false;
  }

  /// Fetch new messages from the Matrix room history.
  ///
  /// **Returns:**
  /// - A list of newly processed [Message]s.
  Future<List<Message>> fetchNewMessages() async {
    final methodName = 'fetchNewMessages';
    _logger.info('Started fetching new messages', name: methodName);
<<<<<<< HEAD
    final messagesFromMediator = await coreSDK.didcomm.fetchMessages(
      did: did,
      mediatorDid: mediatorDid,
      deleteOnRetrieve: false,
=======

    final events = await coreSDK.fetchMatrixRoomHistory(
      roomId: roomId,
      receiverDid: did,
>>>>>>> 6e32091f (chore: first messsaging TODO)
    );

    final newMessages = <Message>[];

<<<<<<< HEAD
    for (final message in messagesFromMediator) {
      if (!await handleMessage(message, newMessages)) {
        chatStream.pushData(
          StreamData(
            event: UnhandledChatEvent(
              type: message.plainTextMessage.type.toString(),
              senderDid: message.plainTextMessage.from,
              body: message.plainTextMessage.body,
              createdTime: message.plainTextMessage.createdTime,
            ),
          ),
        );
      }

      final hash = message.messageHash;
      if (hash != null) processedHashes.add(hash);
    }

    if (processedHashes.isNotEmpty) {
      await coreSDK.didcomm.deleteMessages(
        did: did,
        mediatorDid: mediatorDid,
        messageHashes: processedHashes,
=======
    for (final event in events) {
      final message =
          await chatRepository.createMessage(
                Message.fromRoomEventReceivedByMe(event: event, chatId: chatId),
              )
              as Message;
      chatStream.pushData(
        StreamData(event: event.toChatEvent(), chatItem: message),
>>>>>>> 6e32091f (chore: first messsaging TODO)
      );
      newMessages.add(message);
    }

    _logger.info(
      'Completed loading new messages: ${newMessages.length} new messages',
      name: methodName,
    );
    return newMessages;
  }

  @internal
<<<<<<< HEAD
  Future<SDKStreamSubscription> subscribeToMediator() {
    return coreSDK.didcomm.subscribe(
      did,
      mediatorDid: mediatorDid,
      options: MediatorStreamSubscriptionOptions(
        expectedMessageWrappingTypes:
            coreSDK.options.expectedMessageWrappingTypes,
        fetchMessagesOnConnect: false,
      ),
    );
=======
  Future<StreamSubscription<MatrixRoomEvent>> subscribeToMatrixRoom() async {
    final subscription = coreSDK
        .subscribeToMatrixRoom(
          roomId: roomId,
          receiverDid: did,
          options: const MatrixSubscriptionOptions(excludeSelf: true),
        )
        .listen((event) async {
          await _handleIncomingRoomEvent(event);
        });

    return subscription;
>>>>>>> 6e32091f (chore: first messsaging TODO)
  }

  Future<Message?> _handleIncomingRoomEvent(MatrixRoomEvent event) async {
    if (event.type == 'm.receipt') {
      final serverEventId = event.content['event_id'] as String;
      final localMessageId = _serverEventIdToMessageId[serverEventId];
      if (localMessageId == null) return null;

      final message = await chatRepository.getMessage(
        chatId: chatId,
        messageId: localMessageId,
      );

      if (message == null || !message.isFromMe) return null;
      if (message.status == ChatItemStatus.delivered) return null;

      message.status = ChatItemStatus.delivered;
      await chatRepository.updateMesssage(message);

      chatStream.pushData(
        StreamData(event: const ChatMessageEvent(), chatItem: message),
      );
      return null;
    }

    if (event.type == 'm.reaction') {
      final relatesTo = event.content['m.relates_to'] as Map<String, dynamic>?;
      final targetEventId = relatesTo?['event_id'] as String?;
      final reaction = relatesTo?['key'] as String?;
      if (targetEventId == null || reaction == null) return null;

      final messageId =
          _serverEventIdToMessageId[targetEventId] ?? targetEventId;
      final message = await chatRepository.getMessage(
        chatId: chatId,
        messageId: messageId,
      );
      if (message == null || message is! Message) return null;

      if (!message.reactions.contains(reaction)) {
        message.reactions.add(reaction);
        await chatRepository.updateMesssage(message);
        chatStream.pushData(StreamData(chatItem: message));
        _incomingReactionEventIds[event.id] = '$messageId:$reaction';
      }
      return null;
    }

    if (event.type == 'm.room.redaction') {
      final redactedEventId = event.content['redacts'] as String?;
      if (redactedEventId == null) return null;

      final reactionKey = _incomingReactionEventIds.remove(redactedEventId);
      if (reactionKey == null) return null;

      final separatorIndex = reactionKey.lastIndexOf(':');
      if (separatorIndex == -1) return null;
      final messageId = reactionKey.substring(0, separatorIndex);
      final reaction = reactionKey.substring(separatorIndex + 1);

      final message = await chatRepository.getMessage(
        chatId: chatId,
        messageId: messageId,
      );
      if (message == null || message is! Message) return null;

      if (message.reactions.remove(reaction)) {
        await chatRepository.updateMesssage(message);
        chatStream.pushData(StreamData(chatItem: message));
      }
      return null;
    }

    if (event.type == ChatProtocol.chatEffect.value) {
      chatStream.pushData(StreamData(event: event.toChatEvent()));
      return null;
    }

    final message =
        await chatRepository.createMessage(
              Message.fromRoomEventReceivedByMe(event: event, chatId: chatId),
            )
            as Message;

    unawaited(sendChatDeliveredMessage(event.id));

    chatStream.pushData(
      StreamData(event: event.toChatEvent(), chatItem: message),
    );

    return message;
  }

  /// Sends a custom [CustomMessage] using the chat's sender and recipient
  /// DIDs. No chat item is created or persisted for this type of operation.
  ///
  /// The SDK populates `from` and `to` from its own [did] and [otherPartyDid].
  ///
  /// **Parameters:**
  /// - [message]: The [CustomMessage] to send.
  ///
  /// Returns a [Future] that completes when the message has been sent.
  Future<void> sendMessage(CustomMessage message, {bool notify = false}) {
    final plainTextMessage = PlainTextMessage(
      id: message.id,
      type: Uri.parse(message.type),
      from: did,
      to: [otherPartyDid],
      body: message.body,
      attachments: message.attachments?.map((a) => a.toDIDComm()).toList(),
    );

    return sendDirectMessage(
      plainTextMessage,
      recipientDid: otherPartyDid,
      notify: notify,
    );
  }

  @internal
  Future<void> sendDirectMessage(
    PlainTextMessage message, {
    required String recipientDid,
    bool notify = false,
    bool ephemeral = false,
    int? forwardExpiryInSeconds,
  }) {
    final senderDid = message.from;
    if (senderDid == null || senderDid != did) {
      throw Exception(
        'Message "from" DID ${message.from} does not match chat sender DID '
        '$did.',
      );
    }

    return coreSDK.didcomm.sendMessage(
      PlainTextMessage.fromJson({
        ...message.toJson(),
        'from': senderDid,
        'to': [recipientDid],
      }),
      senderDid: senderDid,
      recipientDid: recipientDid,
      mediatorDid: mediatorDid,
      notifyChannelType: notify ? 'chat-activity' : null,
      ephemeral: ephemeral,
      forwardExpiryInSeconds: forwardExpiryInSeconds,
    );
  }

  /// Sends a plain text message with optional attachments.
  ///
  /// **Parameters:**
  /// - [text]: The plain text content of the message.
  /// - [attachments]: Optional list of [ChatAttachment]s included with
  ///   the message.
  ///
  /// **Returns:**
  /// - The sent [Message] object persisted in the repository.
  Future<Message> sendTextMessage(
    String text, {
    List<ChatAttachment>? attachments,
  }) async {
    final roomEvent = TextMessageRoomEvent.create(
      sender: did,
      roomId: roomId,
      text: text,
    );

    final result = await _sendRoomEventMessage(roomEvent);

    _logger.info('Text message sent', name: _logkey);
    return result;
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
          profileHash: card!.profileHash,
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

  bool _requiresSequenceNumberUpdate(PlainTextMessage message) {
    return coreSDK.options.messageTypesForSequenceTracking.contains(
      message.type.toString(),
    );
  }

  /// Sends an `m.read` receipt for [messageId], marking it as delivered.
  ///
  /// In the Matrix path the [messageId] is the Matrix event ID, so this maps
  /// directly to the native read-marker API.
  Future<void> sendChatDeliveredMessage(String messageId) {
    return coreSDK.sendMatrixRoomEvent(
      ReadReceiptRoomEvent(sender: did, roomId: roomId, eventId: messageId),
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
          await coreSDK.redactMatrixRoomEvent(
            roomId: roomId,
            eventId: reactionEventId,
            senderDid: did,
          );
          _reactionServerEventIds.remove(reactionKey);
        }
      } else {
        final serverEventId = await coreSDK.sendMatrixRoomEvent(
          ReactionRoomEvent(
            sender: did,
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
    _logger.info('Started sending chat effect', name: _logkey);

    final roomEvent = EffectRoomEvent(
      sender: did,
      roomId: roomId,
      effect: effect.name,
    );

    chatStream.pushData(StreamData(event: roomEvent.toChatEvent()));

    // TODO: handle error case
    await coreSDK.sendMatrixRoomEvent(roomEvent);
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
      Message.fromRoomEventSentByMe(event: roomEvent, chatId: chatId),
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
      return await coreSDK.sendMatrixRoomEvent(event);
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
}
