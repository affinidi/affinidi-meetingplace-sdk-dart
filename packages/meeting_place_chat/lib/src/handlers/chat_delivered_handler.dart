import 'package:meeting_place_core/meeting_place_core.dart';

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
    final messageIds = _getMessageIds(message.plainTextMessage);
    for (final messageId in messageIds) {
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

  List<String> _getMessageIds(PlainTextMessage message) {
    return List<String>.from(message.body!['messages'] as List<dynamic>);
  }
}
