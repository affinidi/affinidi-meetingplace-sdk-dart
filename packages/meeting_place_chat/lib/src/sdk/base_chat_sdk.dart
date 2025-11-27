import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';

import '../../meeting_place_chat.dart';
import '../loggers/logger_formatter.dart';
import '../protocol/protocol.dart' as protocol;
import '../utils/chat_utils.dart';
import '../utils/message_utils.dart';
import 'chat.dart';

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
    this.vCard,
    MeetingPlaceChatSDKLogger? logger,
  })  : _logger = LoggerFormatter(className: _className, baseLogger: logger),
        chatStream = ChatStream();

  static const String _className = 'BaseChatSDK';

  final MeetingPlaceCoreSDK coreSDK;
  final String did;
  final String otherPartyDid;
  final String mediatorDid;
  final ChatRepository chatRepository;
  final ChatSDKOptions options;
  final VCard? vCard;
  final MeetingPlaceChatSDKLogger _logger;

  MeetingPlaceChatSDKLogger get logger => _logger;

  ChatStream chatStream;
  CoreSDKStreamSubscription? _mediatorStreamSubscription;
  Future<CoreSDKStreamSubscription>? mediatorStreamFuture;

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
  Future<void> sendMessage(
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
    unawaited(fetchNewMessages());

    final messages = await messagesFuture;
    final chat = Chat(id: chatId, stream: chatStream, messages: messages);

    unawaited(
      mediatorStreamFuture!.then((subscription) {
        _mediatorStreamSubscription = subscription;
        subscription.stream.listen((data) {
          handleMessage(data, []);
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

  /// Handles an incoming [PlainTextMessage].
  ///
  /// Supported message types:
  /// - **Chat message**: Persisted and pushed downstream.
  /// - **Reaction**: Updates existing message reactions.
  /// - **AliasProfileHash / AliasProfileRequest**: Validates or creates concierge messages.
  /// - **Delivered**: Marks referenced messages as delivered.
  /// - **ContactDetailsUpdate**: Updates channel vCard.
  /// - **Activity / Presence / Effect**: Pushed downstream as events.
  ///
  /// **Parameters:**
  /// - [MediatorMessage]: The incoming [MediatorMessage] to process.
  /// - [messages]: A list to collect new [Message] instances.
  @internal
  Future<void> handleMessage(
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

    if (MessageUtils.isType(
      message.plainTextMessage,
      ChatProtocol.chatMessage,
    )) {
      _logger.info('Handling chat message', name: methodName);
      final sequenceNumber =
          message.seqNo ?? message.plainTextMessage.body?['seqNo'] as int;

      final chatMessage = Message.fromReceivedMessage(
        message: message.plainTextMessage,
        chatId: chatId,
      );
      await chatRepository.createMessage(chatMessage);

      if (sequenceNumber > channel.seqNo) {
        channel.seqNo = sequenceNumber;
        await coreSDK.updateChannel(channel);
      }

      chatStream.pushData(
        StreamData(
          plainTextMessage: message.plainTextMessage,
          chatItem: chatMessage,
        ),
      );
    }

    if (message.plainTextMessage.type.toString() ==
        ChatProtocol.chatReaction.value) {
      _logger.info('Handling chat reaction message', name: methodName);
      final chatReaction = ChatReaction.fromMessage(message.plainTextMessage);

      final repositoryMessage = await chatRepository.getMessage(
        chatId: chatId,
        messageId: chatReaction.messageId,
      );

      if (repositoryMessage is! Message) {
        final message = 'Reactions only supported for chat messages';
        _logger.error(message, name: methodName);
        throw Exception(message);
      }

      repositoryMessage.reactions = chatReaction.reactions;
      await chatRepository.updateMesssage(repositoryMessage);

      chatStream.pushData(
        StreamData(
          plainTextMessage: message.plainTextMessage,
          chatItem: repositoryMessage,
        ),
      );
    }

    if (message.plainTextMessage.type.toString() ==
        ChatProtocol.chatAliasProfileHash.value) {
      _logger.info(
        'Handling chat alias profile hash message',
        name: methodName,
      );
      if (channel.type != ChannelType.group) {
        final profileHash = message.plainTextMessage.body?['profileHash'];
        if (profileHash != null && profileHash is String) {
          if (channel.otherPartyVCard?.toHash() == profileHash) {
            chatStream.pushData(
              StreamData(plainTextMessage: message.plainTextMessage),
            );
            return;
          }

          await sendMessage(
            protocol.ChatAliasProfileRequest.create(
              from: did,
              to: [otherPartyDid],
              profileHash: profileHash,
            ),
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
            'profileHash': message.plainTextMessage.body?['profileHash'],
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
    }

    if (message.plainTextMessage.type.toString() ==
        ChatProtocol.chatContactDetailsUpdate.value) {
      _logger.info(
        'Handling chat contact details update message',
        name: methodName,
      );
      if (channel.type != ChannelType.group) {
        channel.otherPartyVCard =
            VCard.fromJson(message.plainTextMessage.body!);

        await coreSDK.updateChannel(channel);
        chatStream.pushData(
          StreamData(plainTextMessage: message.plainTextMessage),
        );
      }
    }

    if (message.plainTextMessage.type.toString() ==
        ChatProtocol.chatActivity.value) {
      _logger.info('Handling chat activity message', name: methodName);
      chatStream.pushData(
        StreamData(plainTextMessage: message.plainTextMessage),
      );
    }

    if (message.plainTextMessage.type.toString() ==
        ChatProtocol.chatPresence.value) {
      _logger.info('Handling chat presence message', name: methodName);
      chatStream.pushData(
        StreamData(plainTextMessage: message.plainTextMessage),
      );
    }

    if (message.plainTextMessage.type.toString() ==
        ChatProtocol.chatEffect.value) {
      _logger.info('Handling chat effect message', name: methodName);
      chatStream.pushData(
        StreamData(plainTextMessage: message.plainTextMessage),
      );
    }

    _logger.info(
      'Completed handling message of type ${message.plainTextMessage.type}',
      name: methodName,
    );
  }

  /// Fetch new messages from the mediator and process them via [handleMessage].
  ///
  /// **Returns:**
  /// - A list of newly processed [Message]s.
  Future<List<Message>> fetchNewMessages() async {
    final methodName = 'fetchNewMessages';
    _logger.info('Started fetching new messages', name: methodName);
    // TODO: delete after processing?
    final messagesFromMediator = await coreSDK.fetchMessages(
      did: did,
      mediatorDid: mediatorDid,
      deleteOnRetrieve: true,
    );
    final newMessages = <Message>[];

    for (final message in messagesFromMediator) {
      await handleMessage(message, newMessages);
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
  /// - A [MediatorStream] subscription.
  ///
  /// **Throws:**
  /// - [Exception] if the chat session has not yet started or resumed.
  @internal
  Future<CoreSDKStreamSubscription> subscribeToMediator() {
    return coreSDK.subscribeToMediator(did, mediatorDid: mediatorDid);
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

    final createdMessage = await chatRepository.createMessage(
      Message.fromSentMessage(message: chatMessage, chatId: chatId),
    );

    try {
      chatStream.pushData(
        StreamData(plainTextMessage: chatMessage, chatItem: createdMessage),
      );

      await sendMessage(
        chatMessage,
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
        notify: true,
      );

      // TODO: add optimistic locking
      final currentMessage = await chatRepository.getMessage(
        chatId: chatId,
        messageId: createdMessage.messageId,
      );

      if (currentMessage!.status == ChatItemStatus.queued) {
        currentMessage.status = ChatItemStatus.sent;
        await chatRepository.updateMesssage(currentMessage);
      }

      await coreSDK.updateChannel(channel);
      chatStream.pushData(
        StreamData(plainTextMessage: chatMessage, chatItem: currentMessage),
      );
      _logger.info('Completed sending text message', name: methodName);
      return currentMessage as Message;
    } catch (e, stackTrace) {
      createdMessage.status = ChatItemStatus.error;
      await chatRepository.updateMesssage(createdMessage);
      _logger.error(
        'Failed to send message',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );

      chatStream.pushData(
        StreamData(plainTextMessage: chatMessage, chatItem: createdMessage),
      );

      return createdMessage as Message;
    }
  }

  /// Sends an ephemeral chat presence signal to the other party.
  Future<void> sendChatPresence() {
    final methodName = 'sendChatPresence';
    _logger.info('Sending chat presence', name: methodName);
    final message = protocol.ChatPresence.create(
      from: did,
      to: [otherPartyDid],
    );

    _logger.info('Completed sending chat presence', name: methodName);
    return sendMessage(
      message,
      senderDid: did,
      recipientDid: otherPartyDid,
      mediatorDid: mediatorDid,
      ephemeral: true,
      forwardExpiryInSeconds: options.chatPresenceExpiry.inSeconds,
    );
  }

  /// Sends a profile hash update if the vCard has changed.
  Future<void> sendProfileHash() async {
    final methodName = 'sendProfileHash';
    _logger.info('Started sending profile hash', name: methodName);
    if (vCard == null) {
      _logger.info(
        'VCard is null, skipping profile hash update',
        name: methodName,
      );
      return;
    }

    final channel = await getChannel();
    if (channel.vCard != null && !vCard!.equals(channel.vCard!)) {
      await sendMessage(
        protocol.ChatAliasProfileHash.create(
          from: did,
          to: [otherPartyDid],
          profileHash: vCard!.toHash(),
        ),
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
      );

      channel.vCard = vCard;
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

  /// Sends a "delivered" acknowledgement for a received message.
  Future<void> sendChatDeliveredMessage(PlainTextMessage message) async {
    final methodName = 'sendChatDeliveredMessage';
    _logger.info('Started sending chat delivered message', name: methodName);
    await sendMessage(
      protocol.ChatDelivered.create(
        from: did,
        to: [otherPartyDid],
        messages: [message.id],
      ),
      senderDid: did,
      recipientDid: otherPartyDid,
      mediatorDid: mediatorDid,
    );

    _logger.info('Completed sending chat delivered message', name: methodName);
  }

  /// Sends updated contact details from the current vCard.
  ///
  /// **Throws:**
  /// - [Exception] if the [vCard] is missing.
  Future<void> sendChatContactDetailsUpdate(ConciergeMessage message) async {
    final methodName = 'sendChatContactDetailsUpdate';
    _logger.info(
      'Started sending chat contact details update',
      name: methodName,
    );
    if (vCard == null) {
      final message = 'Vcard missing for contact details update';
      _logger.error(message, name: methodName);
      // throw Exception('Vcard missing for contact details update');
    }

    unawaited(
      sendMessage(
        protocol.ChatContactDetailsUpdate.create(
          from: did,
          to: [otherPartyDid],
          profileDetails: vCard!.toJson(),
        ),
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
      await sendMessage(
        chatReaction,
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
    );

    chatStream.pushData(StreamData(plainTextMessage: chatEffect));

    // TODO: handle error case
    await sendMessage(
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
    await sendMessage(
      protocol.ChatActivity.create(from: did, to: [otherPartyDid]),
      senderDid: did,
      recipientDid: otherPartyDid,
      mediatorDid: mediatorDid,
      ephemeral: true,
      forwardExpiryInSeconds: options.chatActivityExpiry.inSeconds,
    );
    _logger.info('Completed sending chat activity', name: methodName);
  }

  /// Ends the chat session, disposing of the channel and stream manager.
  void end() async {
    await _mediatorStreamSubscription?.dispose();
    _mediatorStreamSubscription = null;
    mediatorStreamFuture = null;
    chatStream.dispose();
  }

  @internal
  Future<Channel> getChannel() async {
    return await coreSDK.getChannelByOtherPartyPermanentDid(otherPartyDid) ??
        (throw Exception(
            'Channel with other party DID $otherPartyDid not found'));
  }
}
