import '../entity/chat_item.dart';

abstract interface class ChatRepository {
  Future<ChatItem> createMessage(ChatItem message);
  Future<ChatItem> updateMesssage(ChatItem message);
  Future<List<ChatItem>> listMessages(String chatId);
  Future<ChatItem?> getMessage({
    required String chatId,
    required String messageId,
  });

  /// Returns the call chat item whose [callId] matches, or `null` if none
  /// exists. Repository implementations should prefer an indexed or targeted
  /// lookup when available.
  Future<ChatItem?> getCallChatItemByCallId({
    required String chatId,
    required String callId,
  });

  Future<String?> getSyncMarker(String chatId);
  Future<void> updateSyncMarker({
    required String chatId,
    required String eventId,
  });
}
