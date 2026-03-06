import '../../meeting_place_chat.dart';

class ChatAliasProfileRequestHandler {
  ChatAliasProfileRequestHandler({
    required ChatRepository chatRepository,
    required ChatStream streamManager,
  }) : _chatRepository = chatRepository,
       _streamManager = streamManager;

  final ChatRepository _chatRepository;
  final ChatStream _streamManager;

  Future<void> handle({
    required PlainTextMessage message,
    required String chatId,
  }) async {
    final profileRequestMessage =
        ChatAliasProfileRequest.fromPlainTextMessage(message);

    // TODO: delete old concierge messages
    final conciergeMessage = ConciergeMessage(
      chatId: chatId,
      messageId: message.id,
      senderDid: profileRequestMessage.from,
      isFromMe: false,
      dateCreated: message.createdTime ?? DateTime.now().toUtc(),
      status: ChatItemStatus.userInput,
      conciergeType: ConciergeMessageType.permissionToUpdateProfile,
      data: {
        'profileHash': profileRequestMessage.body.profileHash,
        'replyTo': profileRequestMessage.from,
      },
    );

    await _chatRepository.createMessage(conciergeMessage);
    _streamManager.pushData(
      StreamData(plainTextMessage: message, chatItem: conciergeMessage),
    );
  }
}
