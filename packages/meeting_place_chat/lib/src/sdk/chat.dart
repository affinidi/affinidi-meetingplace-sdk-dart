import '../entity/entity.dart';
import '../service/chat_stream.dart';

/// [Chat] represents an active or historical chat session.
///
/// It holds the unique chat ID, an optional live [ChatStream]
/// for receiving messages in real time, and a collection of
/// persisted [ChatItem] messages.
class Chat {
  /// Creates a new [Chat] instance.
  ///
  /// **Parameters:**
  /// - [id]: The unique identifier for this chat (usually derived from DIDs).
  /// - [stream]: An optional [ChatStream] used for live subscriptions.
  /// - [messages]: The list of [ChatItem]s (messages) that belong to this chat.
  Chat({required this.id, required this.stream, required this.messages});

  /// Unique identifier for this chat.
  final String id;

  /// Subscription for receiving events on current chat instance.
  ChatStream? stream;

  /// The collection of chat messages that belong to this chat.
  final List<ChatItem> messages;
}
