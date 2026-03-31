import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';

import '../../meeting_place_chat.dart';
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

  static const _streamOnlyTypes = {
    ChatProtocol.chatActivity,
    ChatProtocol.chatPresence,
    ChatProtocol.chatEffect,
  };

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

    // TODO: sort messages
    _logger.info('Completed chat start', name: methodName);
    return chat;
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
        'Message "from" DID ${message.from} does not match chat sender DID '
        '$did.',
      );
    }

    final recipientDid = message.to?.firstOrNull;
    if (recipientDid == null || recipientDid != otherPartyDid) {
      throw Exception(
        'Message "to" DID ${message.to} does not match chat recipient DID '
        '$otherPartyDid.',
      );
    }

    return sendDirectMessage(
      message,
      recipientDid: recipientDid,
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

    return coreSDK.sendMessage(
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
  /// - [attachments]: Optional list of [Attachment]s included with the message.
  ///
  /// **Returns:**
  /// - The sent [Message] object persisted in the repository.
  Future<Message> sendTextMessage(
    String text, {
    List<Attachment>? attachments,
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

      await _sendMessageWithNotification(plainTextMessage);

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
    _logger.info('Started reacting on message', name: methodName);
    if (message.reactions.contains(reaction)) {
      message.reactions.remove(reaction);
    } else {
      message.reactions.add(reaction);
    }

    await chatRepository.updateMesssage(message);

    final chatReaction = protocol.ChatReaction.create(
      from: did,
      to: [otherPartyDid],
      reactions: message.reactions,
      messageId: message.messageId,
    );

    try {
      await sendPlainTextMessage(
        chatReaction.toPlainTextMessage(),
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to send reaction message',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      // rollback
      message.reactions.remove(reaction);
      await chatRepository.updateMesssage(message);
      Error.throwWithStackTrace(e, stackTrace);
    }

    _logger.info('Completed reacting on message', name: methodName);
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
    await _mediatorStreamSubscription?.dispose();
    _mediatorStreamSubscription = null;
    mediatorStreamFuture = null;
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

  /// Sends a message with notification, ignoring notification failures.
  Future<void> _sendMessageWithNotification(PlainTextMessage message) async {
    try {
      await sendPlainTextMessage(
        message,
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
        notify: true,
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
}
