import 'package:meeting_place_core/meeting_place_core.dart';

import '../transport/didcomm/protocol.dart' as protocol;
import '../transport/matrix/matrix_chat_event_type.dart';
import 'chat_event.dart';
import 'chat_event_types.dart';
import 'incoming_chat_event.dart';

extension MatrixRoomEventToChatEvent on MatrixRoomEvent {
  ChatEvent toChatEvent() {
    // First, try to match against Matrix-specific event types
    if (type == MatrixChatEventType.chatEffect) {
      return ChatEffectEvent(effectName: content['effect'] as String? ?? '');
    }

    // Then, try to match against DIDComm protocol types
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
    final chatProtocol = protocol.ChatProtocol.byValue(type);
    return switch (chatProtocol) {
      protocol.ChatProtocol.chatEffect => ChatEffectEvent(
        effectName: content['effect'] as String? ?? '',
      ),
      _ => const ChatMessageEvent(),
    };
  }
}
