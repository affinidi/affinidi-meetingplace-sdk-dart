import 'chat_event.dart';
import 'chat_event_types.dart';
import 'incoming_chat_event.dart';

extension IncomingChatEventToChatEvent on IncomingChatEvent {
  ChatEvent toChatEvent() => switch (type) {
    ChatEventTypes.chatEffect => ChatEffectEvent(
      effectName: content['effect'] as String? ?? '',
    ),
    _ => const ChatMessageEvent(),
  };
}
