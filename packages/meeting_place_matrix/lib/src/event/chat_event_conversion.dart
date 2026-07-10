import 'package:meeting_place_chat/meeting_place_chat.dart';

import '../matrix_outgoing_message.dart';
import '../matrix_room_event.dart';
import '../transport/matrix/matrix_chat_event_type.dart';

extension MatrixRoomEventToChatEvent on MatrixRoomEvent {
  ChatEvent toChatEvent() {
    if (type == MatrixChatEventType.chatEffect) {
      return ChatEffectEvent(effectName: content['effect'] as String? ?? '');
    }
    final chatProtocol = ChatProtocol.byValue(type);
    return switch (chatProtocol) {
      ChatProtocol.chatEffect => ChatEffectEvent(
        effectName: content['effect'] as String? ?? '',
      ),
      _ => const ChatMessageEvent(),
    };
  }
}

extension IncomingChatEventToChatEvent on IncomingChatEvent {
  ChatEvent toChatEvent() => switch (type) {
    ChatEventTypes.chatEffect => ChatEffectEvent(
      effectName: content['effect'] as String? ?? '',
    ),
    _ => const ChatMessageEvent(),
  };
}

extension MatrixOutgoingMessageToChatEvent on MatrixOutgoingMessage {
  ChatEvent toChatEvent() {
    if (type == MatrixChatEventType.chatEffect) {
      return ChatEffectEvent(effectName: content['effect'] as String? ?? '');
    }
    return const ChatMessageEvent();
  }
}
