import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/transport/didcomm/protocol.dart'
    as protocol;

import '../matrix_room_event.dart';
import '../transport/matrix/matrix_chat_event_type.dart';

extension MatrixRoomEventToChatEvent on MatrixRoomEvent {
  ChatEvent toChatEvent() {
    if (type == MatrixChatEventType.chatEffect) {
      return ChatEffectEvent(effectName: content['effect'] as String? ?? '');
    }
    final chatProtocol = protocol.ChatProtocol.byValue(type);
    return switch (chatProtocol) {
      protocol.ChatProtocol.chatEffect => ChatEffectEvent(
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
