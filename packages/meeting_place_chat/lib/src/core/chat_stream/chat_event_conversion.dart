import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';

import '../../protocol/protocol.dart' as protocol;
import 'chat_event.dart';

@internal
extension PlainTextMessageToChatEvent on PlainTextMessage {
  ChatEvent toChatEvent() {
    final chatProtocol = protocol.ChatProtocol.byValue(type.toString());
    return switch (chatProtocol) {
      protocol.ChatProtocol.chatMessage => const ChatMessageEvent(),
      protocol.ChatProtocol.chatPresence => ChatPresenceEvent(
        timestamp: protocol.ChatPresence.fromPlainTextMessage(
          this,
        ).body.timestamp,
      ),
      protocol.ChatProtocol.chatActivity => ChatActivityEvent(
        senderDid: from,
        timestamp: protocol.ChatActivity.fromPlainTextMessage(
          this,
        ).body.timestamp,
        createdTime: createdTime,
      ),
      protocol.ChatProtocol.chatEffect => ChatEffectEvent(
        effectName: protocol.ChatEffect.fromPlainTextMessage(this).body.effect,
      ),
      protocol.ChatProtocol.chatContactDetailsUpdate =>
        ChatContactDetailsUpdateEvent(
          senderDid: from!,
          contactCard: ContactCard.fromJson(body!),
        ),
      protocol.ChatProtocol.chatGroupDetailsUpdate =>
        const ChatGroupDetailsUpdateEvent(),
      _ => UnhandledChatEvent(
        type: type.toString(),
        senderDid: from,
        body: body,
        createdTime: createdTime,
      ),
    };
  }
}

extension MatrixRoomEventToChatEvent on MatrixRoomEvent {
  ChatEvent toChatEvent() {
    // For simplicity, treating all MatrixRoomEvents as ChatMessageEvents.
    // In a real implementation, you'd inspect the event type and content
    // to determine the appropriate ChatEvent subclass.
    return const ChatMessageEvent();
  }
}
