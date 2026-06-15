import 'dart:async';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart' as didcomm;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../../../meeting_place_chat.dart';
import '../../constants.dart';
import '../../entity/chat_attachment_bytes.dart';
import '../../entity/chat_attachment_conversion.dart';
import '../../logger/default_meeting_place_chat_sdk_logger.dart';
import '../../transport/didcomm/outgoing/outgoing.dart';
import '../../transport/didcomm/protocol.dart' as protocol;
import '../base_chat_sdk.dart';

/// DIDComm-backed implementation of [MeetingPlaceChatSDK] for one-to-one chats.
///
/// All wire traffic flows over DIDComm via the mediator. Subscribes for
/// incoming messages with [DidCommSubscription] and persists/dispatches
/// the protocol payloads inline.
class IndividualDidcommChatSDK extends BaseChatSDK
    implements MeetingPlaceChatSDK {
  IndividualDidcommChatSDK({
    required super.coreSDK,
    required super.did,
    required super.otherPartyDid,
    required super.mediatorDid,
    required super.chatRepository,
    required super.options,
    super.card,
    MeetingPlaceChatSDKLogger? logger,
  }) : super(
         logger:
             logger ??
             DefaultMeetingPlaceChatSDKLogger(
               className: _className,
               sdkName: sdkName,
             ),
       );

  static const String _className = 'IndividualDidcommChatSDK';
  static const String _logkey = 'IndividualDidcommChatSDK';

  StreamSubscription<IncomingMessage>? _subscription;
  IncomingMessageHandle? _subscriptionHandle;
  bool _isSendingChatPresence = false;
  int _seqNo = 0;

  @override
  Future<Chat> startChatSession() async {
    chatStream = ChatStream();

    final subscribeFuture = _subscribe();
    transportSubscriptionFuture = subscribeFuture;

    unawaited(proposeProfileUpdate());

    final channel = await getChannel();
    _seqNo = channel.seqNo;

    final persisted = await chatRepository.listMessages(chatId);
    final chat = Chat(id: chatId, stream: chatStream, messages: persisted);

    unawaited(
      subscribeFuture.then((sub) {
        _subscription = sub;
      }),
    );

    unawaited(startChatPresenceUpdates());

    logger.info('DIDComm chat session initialised', name: _logkey);
    return chat;
  }

  Future<StreamSubscription<IncomingMessage>> _subscribe() async {
    _subscriptionHandle = await coreSDK.subscribe(
      DidCommSubscription(receiverDid: did, mediatorDid: mediatorDid),
    );

    return _subscriptionHandle!.stream
        .where((m) => m is DidCommIncomingMessage)
        .cast<DidCommIncomingMessage>()
        .where((m) => m.payload.from == otherPartyDid)
        .listen(_handleIncoming);
  }

  Future<void> _handleIncoming(DidCommIncomingMessage incoming) async {
    final payload = incoming.payload;
    final type = payload.type.toString();
    final chatProtocol = protocol.ChatProtocol.byValue(type) ?? type;

    switch (chatProtocol) {
      case protocol.ChatProtocol.chatMessage:
        await _handleIncomingChatMessage(payload);
        break;
      case protocol.ChatProtocol.chatReaction:
        await _handleIncomingReaction(payload);
        break;
      case protocol.ChatProtocol.chatDelivered:
        await _handleIncomingDelivered(payload);
        break;
      case protocol.ChatProtocol.chatAliasProfileHash:
        await _handleIncomingProfileHash(payload);
        break;
      case protocol.ChatProtocol.chatAliasProfileRequest:
        await _handleIncomingProfileRequest(payload);
        break;
      case protocol.ChatProtocol.chatContactDetailsUpdate:
        await _handleIncomingContactDetailsUpdate(payload);
        break;
      case protocol.ChatProtocol.chatEffect:
        chatStream.pushData(
          StreamData(
            event: ChatEffectEvent(
              effectName: (payload.body?['effect'] as String?) ?? '',
            ),
          ),
        );
        break;
      case protocol.ChatProtocol.chatActivity:
        final now = DateTime.now().toUtc();
        chatStream.pushData(
          StreamData(
            event: ChatActivityEvent(
              senderDid: payload.from ?? otherPartyDid,
              timestamp: now,
              createdTime: payload.createdTime,
            ),
          ),
        );
        break;
      case protocol.ChatProtocol.chatPresence:
        chatStream.pushData(
          StreamData(
            event: ChatPresenceEvent(timestamp: DateTime.now().toUtc()),
          ),
        );
        break;
      case final String vdipType
          when vdipType == VdipClient.requestIssuanceMessageType:
        coreSDK.vdip.dispatch(incoming.payload);

        chatStream.pushData(
          StreamData(
            event: ChatRequestIssuanceEvent(
              senderDid: payload.from,
              body: payload.body ?? const {},
              createdTime: payload.createdTime ?? DateTime.now().toUtc(),
              attachments: payload.attachments ?? const [],
            ),
          ),
        );
        break;
      case final String vdipType
          when vdipType == VdipClient.issuedCredentialMessageType:
        coreSDK.vdip.dispatch(incoming.payload);

        chatStream.pushData(
          StreamData(
            event: ChatIssuedCredentialEvent(
              senderDid: payload.from,
              body: payload.body ?? const {},
              createdTime: payload.createdTime ?? DateTime.now().toUtc(),
              attachments: payload.attachments ?? const [],
            ),
          ),
        );
        break;
      default:
        chatStream.pushData(
          StreamData(
            event: UnhandledChatEvent(
              type: type,
              senderDid: payload.from,
              body: payload.body ?? const {},
              createdTime: payload.createdTime ?? DateTime.now().toUtc(),
            ),
          ),
        );
    }
  }

  Future<void> _handleIncomingProfileHash(didcomm.PlainTextMessage p) async {
    final profileHashMessage =
        protocol.ChatAliasProfileHash.fromPlainTextMessage(p);
    final incomingHash = profileHashMessage.body.profileHash;

    final channel = await getChannel();
    final storedHash = channel.otherPartyContactCard?.profileHash;

    if (storedHash != incomingHash) {
      await coreSDK.sendMessage(
        ChatAliasProfileRequestMessage(
          senderDid: did,
          recipientDid: otherPartyDid,
          mediatorDid: mediatorDid,
          profileHash: incomingHash,
        ),
      );
    }

    chatStream.pushData(
      StreamData(
        event: ChatProfileHashEvent(
          senderDid: p.from ?? otherPartyDid,
          profileHash: incomingHash,
        ),
      ),
    );
  }

  Future<void> _handleIncomingProfileRequest(didcomm.PlainTextMessage p) async {
    final profileRequest =
        protocol.ChatAliasProfileRequest.fromPlainTextMessage(p);

    final channel = await getChannel();
    final replyTo = channel.otherPartyContactCard?.did ?? profileRequest.from;

    final conciergeMessage = ConciergeMessage(
      chatId: chatId,
      messageId: p.id,
      senderDid: profileRequest.from,
      isFromMe: false,
      dateCreated: p.createdTime ?? DateTime.now().toUtc(),
      status: ChatItemStatus.userInput,
      conciergeType: ConciergeMessageType.permissionToUpdateProfile,
      data: {
        'profileHash': profileRequest.body.profileHash,
        'replyTo': replyTo,
      },
    );

    final created = await chatRepository.createMessage(conciergeMessage);
    chatStream.pushData(
      StreamData(
        event: ChatProfileRequestEvent(
          senderDid: profileRequest.from,
          profileHash: profileRequest.body.profileHash,
        ),
        chatItem: created,
      ),
    );
  }

  Future<void> _handleIncomingContactDetailsUpdate(
    didcomm.PlainTextMessage p,
  ) async {
    final update = protocol.ChatContactDetailsUpdate.fromPlainTextMessage(p);
    final updatedCard = ContactCard.fromJson(update.profileDetails);

    final channel = await getChannel();
    channel.otherPartyContactCard = updatedCard;
    await coreSDK.updateChannel(channel);

    chatStream.pushData(
      StreamData(
        event: ChatContactDetailsUpdateEvent(
          senderDid: p.from ?? otherPartyDid,
          contactCard: updatedCard,
        ),
      ),
    );
  }

  Future<void> _handleIncomingChatMessage(didcomm.PlainTextMessage p) async {
    final chatMessage = protocol.ChatMessage.fromPlainTextMessage(p);
    final message = Message.fromReceivedMessage(
      message: chatMessage,
      chatId: chatId,
    );
    final created = await chatRepository.createMessage(message);

    _seqNo = chatMessage.body.seqNo;
    final channel = await getChannel();
    if (channel.seqNo < _seqNo) {
      channel.seqNo = _seqNo;
      await coreSDK.updateChannel(channel);
    }

    chatStream.pushData(
      StreamData(event: const ChatMessageEvent(), chatItem: created),
    );

    unawaited(sendChatDeliveredMessage(message.messageId));
  }

  Future<void> _handleIncomingReaction(didcomm.PlainTextMessage p) async {
    final reaction = protocol.ChatReaction.fromPlainTextMessage(p);
    final target = await chatRepository.getMessage(
      chatId: chatId,
      messageId: reaction.body.messageId,
    );
    if (target == null) return;
    if (target is Message) {
      target.reactions
        ..clear()
        ..addAll(reaction.body.reactions);
      await chatRepository.updateMesssage(target);
      chatStream.pushData(StreamData(chatItem: target));
    }
  }

  Future<void> _handleIncomingDelivered(didcomm.PlainTextMessage p) async {
    final delivered = protocol.ChatDelivered.fromPlainTextMessage(p);
    for (final messageId in delivered.body.messages) {
      final target = await chatRepository.getMessage(
        chatId: chatId,
        messageId: messageId,
      );
      if (target is Message) {
        target.status = ChatItemStatus.delivered;
        await chatRepository.updateMesssage(target);
        chatStream.pushData(StreamData(chatItem: target));
      }
    }
    chatStream.pushData(
      StreamData(
        event: ChatMessageDeliveredEvent(
          messageIds: List<String>.unmodifiable(delivered.body.messages),
        ),
      ),
    );
  }

  @override
  Future<List<ChatItem>> get messages {
    logger.info('Retrieving persisted messages', name: _logkey);
    return chatRepository.listMessages(chatId);
  }

  @override
  Future<Message> sendTextMessage(
    String text, {
    List<ChatAttachment> attachments = const [],
  }) async {
    assertCanSend();
    final channel = await getChannel();
    channel.increaseSeqNo();
    _seqNo = channel.seqNo;

    final chatMessage = protocol.ChatMessage.create(
      from: did,
      to: [otherPartyDid],
      text: text,
      seqNo: _seqNo,
      attachments: attachments.map((a) => a.toDIDComm()).toList(),
    );

    final created = await chatRepository.createMessage(
      Message.fromSentMessage(message: chatMessage, chatId: chatId),
    );

    try {
      chatStream.pushData(StreamData(chatItem: created));

      await _sendWithNotification(
        ChatTextMessage(
          senderDid: did,
          recipientDid: otherPartyDid,
          mediatorDid: mediatorDid,
          chatMessage: chatMessage,
          notifyChannelType: 'chat-activity',
        ),
      );

      if (created is Message && created.status == ChatItemStatus.queued) {
        created.status = ChatItemStatus.sent;
        await chatRepository.updateMesssage(created);
      }

      await coreSDK.updateChannel(channel);
      chatStream.pushData(StreamData(chatItem: created));
      return created as Message;
    } catch (e, stackTrace) {
      created.status = ChatItemStatus.error;
      await chatRepository.updateMesssage(created);
      logger.error(
        'Failed to send text message',
        error: e,
        stackTrace: stackTrace,
        name: _logkey,
      );
      chatStream.pushData(StreamData(chatItem: created));
      return created as Message;
    }
  }

  @override
  Future<Uint8List> downloadMedia(ChatAttachment attachment) async {
    return attachment.decodeInlineBytes();
  }

  @override
  Future<void> sendChatDeliveredMessage(String messageId) async {
    assertCanSend();
    await coreSDK.sendMessage(
      ChatDeliveredMessage(
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
        messageIds: [messageId],
      ),
    );
  }

  @override
  Future<void> reactOnMessage(
    Message message, {
    required String reaction,
  }) async {
    assertCanSend();
    final isRemoving = message.reactions.contains(reaction);
    if (isRemoving) {
      message.reactions.remove(reaction);
    } else {
      message.reactions.add(reaction);
    }
    await chatRepository.updateMesssage(message);

    try {
      await coreSDK.sendMessage(
        ChatReactionMessage(
          senderDid: did,
          recipientDid: otherPartyDid,
          mediatorDid: mediatorDid,
          reactions: message.reactions,
          messageId: message.messageId,
        ),
      );
    } catch (e, stackTrace) {
      if (isRemoving) {
        message.reactions.add(reaction);
      } else {
        message.reactions.remove(reaction);
      }
      await chatRepository.updateMesssage(message);
      logger.error(
        'Failed to send reaction',
        error: e,
        stackTrace: stackTrace,
        name: _logkey,
      );
      Error.throwWithStackTrace(e, stackTrace);
    }
  }

  @override
  Future<void> editTextMessage(Message message, String newText) {
    throw UnimplementedError(
      'editTextMessage is not yet supported on the DIDComm individual chat '
      'SDK.',
    );
  }

  @override
  Future<void> deleteMessage(Message message, {bool localOnly = false}) {
    throw UnsupportedError(
      'Message deletion is not supported over DIDComm transport.',
    );
  }

  @override
  Future<void> sendEffect(Effect effect) async {
    assertCanSend();
    await coreSDK.sendMessage(
      ChatEffectMessage(
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
        effect: effect.name,
      ),
    );
  }

  @override
  Future<void> sendChatPresence() async {
    assertCanSend();
    await coreSDK.sendMessage(
      ChatPresenceMessage(
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
        forwardExpiry: options.chatPresenceExpiry,
      ),
    );
  }

  @override
  Future<void> sendChatActivity() async {
    assertCanSend();
    await coreSDK.sendMessage(
      ChatActivityMessage(
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
        forwardExpiry: options.chatActivityExpiry,
      ),
    );
  }

  @override
  Future<void> sendChatContactDetailsUpdate(ConciergeMessage message) async {
    assertCanSend();
    final c = card;
    if (c == null) {
      throw StateError('ContactCard missing for contact details update');
    }

    unawaited(
      coreSDK.sendMessage(
        ChatContactDetailsUpdateMessage(
          senderDid: did,
          recipientDid: otherPartyDid,
          mediatorDid: mediatorDid,
          profileDetails: c.toJson(),
        ),
      ),
    );

    message.status = ChatItemStatus.confirmed;
    await chatRepository.updateMesssage(message);
    chatStream.pushData(StreamData(chatItem: message));
  }

  @override
  Future<void> proposeProfileUpdate() async {
    if (card == null) {
      logger.info(
        'ContactCard is null, skipping profile hash update',
        name: _logkey,
      );
      return;
    }

    final channel = await getChannel();
    if (channel.contactCard != null && !card!.equals(channel.contactCard!)) {
      await coreSDK.sendMessage(
        ChatAliasProfileHashMessage(
          senderDid: did,
          recipientDid: otherPartyDid,
          mediatorDid: mediatorDid,
          profileHash: card!.profileHash,
        ),
      );

      channel.contactCard = card;
      await coreSDK.updateChannel(channel);
    }
  }

  /// Sends a custom [PlainTextMessage] via DIDComm. Only available on the
  /// DIDComm individual SDK — not part of the shared [MeetingPlaceChatSDK]
  /// interface.
  Future<void> sendPlainTextMessage(
    didcomm.PlainTextMessage message, {
    bool notify = false,
    bool ephemeral = false,
    int? forwardExpiryInSeconds,
  }) async {
    assertCanSend();
    await coreSDK.sendMessage(
      _RawDidCommOutgoingMessage(
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
        payload: message,
        notifyChannelType: notify ? 'chat-activity' : null,
        ephemeral: ephemeral,
        forwardExpiryInSeconds: forwardExpiryInSeconds,
      ),
    );
  }

  @override
  Future<void> sendCustomEvent({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    assertCanSend();
    final message = didcomm.PlainTextMessage(
      id: const Uuid().v4(),
      type: Uri.parse(type),
      from: did,
      to: [otherPartyDid],
      createdTime: DateTime.now().toUtc(),
      body: payload,
    );
    await coreSDK.sendMessage(
      _RawDidCommOutgoingMessage(
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
        payload: message,
      ),
    );
    logger.info('Sent custom DIDComm message of type $type', name: _logkey);
  }

  Future<void> _sendWithNotification(DidCommOutgoingMessage outgoing) async {
    try {
      await coreSDK.sendMessage(outgoing);
    } on MeetingPlaceCoreSDKException catch (e) {
      final isNotificationError =
          e.code ==
          MeetingPlaceCoreSDKErrorCode.channelNotificationFailed.value;
      if (!isNotificationError) rethrow;
      logger.warning(
        'Notification failed for ${outgoing.payload.type}',
        name: _logkey,
      );
    }
  }

  @override
  Future<void> startChatPresenceUpdates() async =>
      _startChatPresenceInInterval(options.chatPresenceSendInterval.inSeconds);

  Future<void> _startChatPresenceInInterval(int intervalInSeconds) async {
    if (_isSendingChatPresence) return;
    _isSendingChatPresence = true;
    while (_isSendingChatPresence) {
      try {
        await sendChatPresence();
        await Future<void>.delayed(Duration(seconds: intervalInSeconds));
      } catch (e) {
        logger.error('Error sending chat presence signal: $e');
        stopChatPresenceInterval();
      }
    }
  }

  void stopChatPresenceInterval() {
    _isSendingChatPresence = false;
  }

  @override
  Future<void> endChatSession() async {
    stopChatPresenceInterval();
    await _subscription?.cancel();
    _subscription = null;
    await _subscriptionHandle?.dispose();
    _subscriptionHandle = null;
    await super.end();
  }

  @override
  Future<void> approveConnectionRequest(ConciergeMessage message) {
    throw UnimplementedError();
  }

  @override
  Future<void> rejectConnectionRequest(ConciergeMessage message) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeMember(String memberDid) {
    throw UnimplementedError();
  }
}

// ignore: unused_element
class _RawDidCommOutgoingMessage extends DidCommOutgoingMessage {
  const _RawDidCommOutgoingMessage({
    required super.senderDid,
    required super.recipientDid,
    required super.mediatorDid,
    required super.payload,
    super.notifyChannelType,
    super.ephemeral,
    super.forwardExpiryInSeconds,
  });
}
