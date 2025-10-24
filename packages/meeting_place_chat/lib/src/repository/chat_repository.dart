import '../entity/chat_item.dart';

abstract interface class ChatRepository {
  Future<ChatItem> createMessage(ChatItem message);
  Future<ChatItem> updateMesssage(ChatItem message);
  Future<List<ChatItem>> listMessages(String chatId);
  Future<ChatItem?> getMessage({
    required String chatId,
    required String messageId,
  });
}
