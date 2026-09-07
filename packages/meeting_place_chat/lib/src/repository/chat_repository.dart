import '../entity/chat_item.dart';

/// Consumer-implemented persistence contract for a chat's [ChatItem]s.
///
/// The chat SDK reads and writes through this interface for every message
/// operation; app code supplies the concrete storage (e.g. Drift, an
/// in-memory store) by implementing it.
abstract interface class ChatRepository {
  /// Persists [message] as a new chat item and returns the stored value.
  ///
  /// Implementations should key storage by [ChatItem.chatId] and
  /// [ChatItem.messageId] so [getMessage] can look it up afterwards.
  Future<ChatItem> createMessage(ChatItem message);

  /// Persists changes to an existing [message] and returns the updated
  /// value.
  ///
  /// Implementations should overwrite the stored item that shares
  /// [ChatItem.chatId] and [ChatItem.messageId] with [message].
  Future<ChatItem> updateMesssage(ChatItem message);

  /// Returns all chat items stored for [chatId].
  Future<List<ChatItem>> listMessages(String chatId);

  /// Returns the chat items in [chatId] whose attachments carry the given
  /// [mediaKind], most recent first, capped to [limit] entries when
  /// provided.
  Future<List<ChatItem>> listMessagesByMediaKind(
    String chatId, {
    required String mediaKind,
    int? limit,
  });

  /// Returns the chat item identified by [chatId] and [messageId], or
  /// `null` if no such item is stored.
  Future<ChatItem?> getMessage({
    required String chatId,
    required String messageId,
  });

  /// Returns the last sync cursor stored for [chatId], or `null` if none has
  /// been recorded yet. Used by transports that page through remote history
  /// (e.g. Matrix) to resume from where they left off.
  Future<String?> getSyncMarker(String chatId);

  /// Persists [eventId] as the sync cursor for [chatId], overwriting any
  /// previous marker.
  Future<void> updateSyncMarker({
    required String chatId,
    required String eventId,
  });
}
