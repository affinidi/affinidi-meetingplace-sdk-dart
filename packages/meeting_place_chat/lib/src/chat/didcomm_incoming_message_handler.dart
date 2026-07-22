import 'package:didcomm/didcomm.dart' as didcomm;
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_chat.dart';
import '../transport/didcomm/outgoing/outgoing.dart';
import '../transport/didcomm/protocol.dart' as protocol;

typedef IncomingDidcommSeqNoObserver = Future<void> Function(int seqNo);

/// Handles DIDComm chat payloads for SDKs that consume mediator traffic.
class DidcommIncomingMessageHandler {
  DidcommIncomingMessageHandler({
    required this.coreSDK,
    required this.chatRepository,
    required this.chatStream,
    required this.chatId,
    required this.did,
    required this.otherPartyDid,
    required this.mediatorDid,
    required this.logger,
    required this.getChannel,
    this.onSeqNoObserved,
  });

  static const String _logkey = 'DidcommIncomingMessageHandler';

  final MeetingPlaceCoreSDK coreSDK;
  final ChatRepository chatRepository;
  final ChatStream chatStream;
  final String chatId;
  final String did;
  final String otherPartyDid;
  final String mediatorDid;
  final MeetingPlaceChatSDKLogger logger;
  final Future<Channel> Function() getChannel;
  final IncomingDidcommSeqNoObserver? onSeqNoObserved;

  Future<void> handle(DidCommIncomingMessage incoming) async {
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
      case protocol.ChatProtocol.suggestion:
        final suggestion = protocol.ChatSuggestion.fromPlainTextMessage(
          payload,
        );
        chatStream.pushData(
          StreamData(
            event: ChatSuggestionEvent(
              senderDid: suggestion.from,
              relatedMessageId: suggestion.body.relatedMessageId,
              text: suggestion.body.text,
              createdTime: suggestion.createdTime,
            ),
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

  Future<void> _handleIncomingProfileHash(
    didcomm.PlainTextMessage message,
  ) async {
    final profileHashMessage =
        protocol.ChatAliasProfileHash.fromPlainTextMessage(message);
    final incomingHash = profileHashMessage.body.profileHash;

    final channel = await getChannel();
    final storedHash = channel.otherPartyContactCard?.profileHash;

    if (storedHash != incomingHash) {
      await coreSDK.sendMessage(
        ChatAliasProfileRequestMessage(
          senderDid: did,
          recipientDid: message.from ?? otherPartyDid,
          mediatorDid: mediatorDid,
          profileHash: incomingHash,
        ),
      );
    }

    chatStream.pushData(
      StreamData(
        event: ChatProfileHashEvent(
          senderDid: message.from ?? otherPartyDid,
          profileHash: incomingHash,
        ),
      ),
    );
  }

  Future<void> _handleIncomingProfileRequest(
    didcomm.PlainTextMessage message,
  ) async {
    final profileRequest =
        protocol.ChatAliasProfileRequest.fromPlainTextMessage(message);

    final channel = await getChannel();
    final replyTo = channel.otherPartyContactCard?.did ?? profileRequest.from;

    final conciergeMessage = ConciergeMessage(
      chatId: chatId,
      messageId: message.id,
      senderDid: profileRequest.from,
      isFromMe: false,
      dateCreated: message.createdTime ?? DateTime.now().toUtc(),
      status: ChatItemStatus.userInput,
      conciergeType: ConciergeMessageType.permissionToUpdateProfile,
      data: {
        'profileHash': profileRequest.body.profileHash,
        'replyTo': replyTo,
      },
    );

    final existing = await chatRepository.getMessage(
      chatId: chatId,
      messageId: message.id,
    );
    final created =
        existing ?? await chatRepository.createMessage(conciergeMessage);

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
    didcomm.PlainTextMessage message,
  ) async {
    final update = protocol.ChatContactDetailsUpdate.fromPlainTextMessage(
      message,
    );
    final updatedCard = ContactCard.fromJson(update.profileDetails);

    final channel = await getChannel();
    channel.otherPartyContactCard = updatedCard;
    await coreSDK.updateChannel(channel);

    chatStream.pushData(
      StreamData(
        event: ChatContactDetailsUpdateEvent(
          senderDid: message.from ?? otherPartyDid,
          contactCard: updatedCard,
        ),
      ),
    );
  }

  Future<void> _handleIncomingChatMessage(
    didcomm.PlainTextMessage message,
  ) async {
    final chatMessage = protocol.ChatMessage.fromPlainTextMessage(message);

    final signRequest = CiergeSignDocumentRequest.fromMessageText(
      chatMessage.body.text,
    );
    if (signRequest != null) {
      final concierge = ConciergeMessage(
        chatId: chatId,
        messageId: chatMessage.id,
        senderDid: chatMessage.from,
        isFromMe: false,
        dateCreated: chatMessage.createdTime,
        status: ChatItemStatus.userInput,
        conciergeType: ConciergeMessageType.fromJson(
          CiergeSignDocumentRequest.conciergeTypeName,
        ),
        data: {'document': signRequest.document, 'taskId': signRequest.taskId},
      );
      final existing = await chatRepository.getMessage(
        chatId: chatId,
        messageId: chatMessage.id,
      );
      final created = existing ?? await chatRepository.createMessage(concierge);
      chatStream.pushData(
        StreamData(event: const ChatMessageEvent(), chatItem: created),
      );
      await _sendDeliveredReceipt(
        chatMessage.id,
        recipientDid: chatMessage.from,
      );
      return;
    }

    final stepUpRequest = CiergeStepUpApproveRequest.fromMessageText(
      chatMessage.body.text,
    );
    if (stepUpRequest != null) {
      final concierge = ConciergeMessage(
        chatId: chatId,
        messageId: chatMessage.id,
        senderDid: chatMessage.from,
        isFromMe: false,
        dateCreated: chatMessage.createdTime,
        status: ChatItemStatus.userInput,
        conciergeType: ConciergeMessageType.fromJson(
          CiergeStepUpApproveRequest.conciergeTypeName,
        ),
        data: {'approveRequest': stepUpRequest.approveRequest},
      );
      final existing = await chatRepository.getMessage(
        chatId: chatId,
        messageId: chatMessage.id,
      );
      final created = existing ?? await chatRepository.createMessage(concierge);
      chatStream.pushData(
        StreamData(event: const ChatMessageEvent(), chatItem: created),
      );
      await _sendDeliveredReceipt(
        chatMessage.id,
        recipientDid: chatMessage.from,
      );
      return;
    }

    final existing = await chatRepository.getMessage(
      chatId: chatId,
      messageId: chatMessage.id,
    );
    if (existing is Message) {
      chatStream.pushData(
        StreamData(event: const ChatMessageEvent(), chatItem: existing),
      );
      return;
    }

    final persistedMessage = Message.fromReceivedMessage(
      message: chatMessage,
      chatId: chatId,
    );
    final created = await chatRepository.createMessage(persistedMessage);

    await onSeqNoObserved?.call(chatMessage.body.seqNo);

    chatStream.pushData(
      StreamData(event: const ChatMessageEvent(), chatItem: created),
    );

    await _sendDeliveredReceipt(chatMessage.id, recipientDid: chatMessage.from);
  }

  Future<void> _handleIncomingReaction(didcomm.PlainTextMessage message) async {
    final reaction = protocol.ChatReaction.fromPlainTextMessage(message);
    final target = await chatRepository.getMessage(
      chatId: chatId,
      messageId: reaction.body.messageId,
    );
    if (target is! Message) return;

    final from = reaction.from;
    target.reactions
      ..removeWhere((r) => r.senderDid == from)
      ..addAll(
        reaction.body.reactions.map(
          (emoji) => MessageReaction(emoji: emoji, senderDid: from),
        ),
      );
    await chatRepository.updateMesssage(target);
    chatStream.pushData(StreamData(chatItem: target));
  }

  Future<void> _handleIncomingDelivered(
    didcomm.PlainTextMessage message,
  ) async {
    final delivered = protocol.ChatDelivered.fromPlainTextMessage(message);
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

  Future<void> _sendDeliveredReceipt(
    String messageId, {
    required String recipientDid,
  }) async {
    try {
      await coreSDK.sendMessage(
        ChatDeliveredMessage(
          senderDid: did,
          recipientDid: recipientDid,
          mediatorDid: mediatorDid,
          messageIds: [messageId],
        ),
      );
    } catch (error) {
      logger.warning(
        'Failed to send chat delivered receipt for $messageId: $error',
        name: _logkey,
      );
    }
  }
}
