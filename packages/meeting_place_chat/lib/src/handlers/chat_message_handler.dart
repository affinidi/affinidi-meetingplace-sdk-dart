import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_chat.dart';
import '../core/chat_stream/chat_event_conversion.dart';

class ChatMessageHandler {
  ChatMessageHandler({
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
    final chatMessage = Message.fromReceivedMessage(
      message: ChatMessage.fromPlainTextMessage(message.plainTextMessage),
      chatId: chatId,
    );
    await _chatRepository.createMessage(chatMessage);
    _streamManager.pushData(
      StreamData(
        event: message.plainTextMessage.toChatEvent(),
        chatItem: chatMessage,
      ),
    );
  }
}
