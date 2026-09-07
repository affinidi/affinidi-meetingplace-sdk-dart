import 'chat_event.dart';
import 'chat_event_types.dart';
import 'incoming_chat_event.dart';

/// Converts a transport-neutral [IncomingChatEvent] into the corresponding
/// [ChatEvent] emitted on the chat stream.
extension IncomingChatEventToChatEvent on IncomingChatEvent {
  /// Maps [IncomingChatEvent.type] to a concrete [ChatEvent] subtype,
  /// falling back to [ChatMessageEvent] for unrecognized types.
  ChatEvent toChatEvent() => switch (type) {
    ChatEventTypes.chatEffect => ChatEffectEvent(
      effectName: content['effect'] as String? ?? '',
    ),
    _ => const ChatMessageEvent(),
  };
}
