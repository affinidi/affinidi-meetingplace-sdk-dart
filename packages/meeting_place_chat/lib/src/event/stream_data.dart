import '../entity/chat_item.dart';
import 'chat_event.dart';

/// A single item delivered on a `ChatStream`.
///
/// Carries [event] (the transport event, e.g. typing indicator or delivery
/// receipt) and/or [chatItem] (the persisted chat item it relates to, e.g.
/// a new or updated message), depending on what the event represents.
class StreamData {
  /// Creates a [StreamData].
  StreamData({this.event, this.chatItem});

  /// The chat event carried by this stream item, if any.
  final ChatEvent? event;

  /// The chat item this stream item relates to, if any.
  final ChatItem? chatItem;
}
