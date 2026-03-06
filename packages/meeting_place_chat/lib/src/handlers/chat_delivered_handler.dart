import '../../meeting_place_chat.dart';

class ChatDeliveredHandler {
  ChatDeliveredHandler({
    required ChatRepository chatRepository,
    required ChatStream streamManager,
  }) : _chatRepository = chatRepository,
       _streamManager = streamManager;

  final ChatRepository _chatRepository;
  final ChatStream _streamManager;

  Future<void> handle({
    required MediatorMessage message,
    required String chatId,
  }) async {
    final deliveredMessage =
        ChatDelivered.fromPlainTextMessage(message.plainTextMessage);

    for (final messageId in deliveredMessage.body.messages) {
      final targetMessage = await _chatRepository.getMessage(
        chatId: chatId,
        messageId: messageId,
      );

      if (targetMessage == null) continue;

      targetMessage.status = ChatItemStatus.delivered;
      await _chatRepository.updateMesssage(targetMessage);

      _streamManager.pushData(
        StreamData(
          plainTextMessage: message.plainTextMessage,
          chatItem: targetMessage,
        ),
      );
    }
  }
}
