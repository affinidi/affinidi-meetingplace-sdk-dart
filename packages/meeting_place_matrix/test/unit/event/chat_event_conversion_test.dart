import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/src/event/chat_event_conversion.dart';
import 'package:meeting_place_matrix/src/transport/matrix/outgoing/effect_room_event.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:test/test.dart';

void main() {
  group('MatrixRoomEvent.toChatEvent (DIDComm-URI based mapping)', () {
    test('chat-effect DIDComm URI yields ChatEffectEvent with effectName', () {
      final event = MatrixRoomEvent(
        id: 'evt-1',
        type: ChatProtocol.chatEffect.value,
        senderDid: 'did:test:alice',
        roomId: '!room:server',
        content: const {'effect': 'confetti'},
        timestamp: DateTime.utc(2026, 1, 1),
      );

      final chatEvent = event.toChatEvent();
      expect(chatEvent, isA<ChatEffectEvent>());
      expect((chatEvent as ChatEffectEvent).effectName, 'confetti');
    });

    test('missing effect field falls back to empty string', () {
      final event = MatrixRoomEvent(
        id: 'evt-1',
        type: ChatProtocol.chatEffect.value,
        senderDid: 'did:test:alice',
        roomId: '!room:server',
        content: const {},
        timestamp: DateTime.utc(2026, 1, 1),
      );

      final chatEvent = event.toChatEvent() as ChatEffectEvent;
      expect(chatEvent.effectName, '');
    });

    test('unmapped event type falls back to ChatMessageEvent', () {
      final event = MatrixRoomEvent(
        id: 'evt-1',
        type: 'm.room.message',
        senderDid: 'did:test:alice',
        roomId: '!room:server',
        content: const {},
        timestamp: DateTime.utc(2026, 1, 1),
      );

      expect(event.toChatEvent(), isA<ChatMessageEvent>());
    });
  });

  group('IncomingChatEvent.toChatEvent (ChatEventTypes-based mapping)', () {
    test('chat.effect dispatch key yields ChatEffectEvent', () {
      final event = IncomingChatEvent(
        type: ChatEventTypes.chatEffect,
        senderDid: 'did:test:alice',
        content: const {'effect': 'balloons'},
      );

      final chatEvent = event.toChatEvent();
      expect(chatEvent, isA<ChatEffectEvent>());
      expect((chatEvent as ChatEffectEvent).effectName, 'balloons');
    });

    test('unknown dispatch key falls back to ChatMessageEvent', () {
      final event = IncomingChatEvent(
        type: 'something.else',
        senderDid: 'did:test:alice',
        content: const {},
      );

      expect(event.toChatEvent(), isA<ChatMessageEvent>());
    });
  });

  group('MatrixOutgoingMessageToChatEvent (FIX 2 regression)', () {
    test('EffectRoomEvent with Matrix-native type yields ChatEffectEvent '
        'so the sender sees their own animation', () {
      final outgoing = EffectRoomEvent(
        senderDid: 'did:test:alice',
        effect: 'confetti',
      );

      final chatEvent = outgoing.toChatEvent();
      expect(chatEvent, isA<ChatEffectEvent>());
      expect((chatEvent as ChatEffectEvent).effectName, 'confetti');
    });

    test('balloons effect name is preserved through outgoing conversion', () {
      final outgoing = EffectRoomEvent(
        senderDid: 'did:test:alice',
        effect: 'balloons',
      );

      final chatEvent = outgoing.toChatEvent() as ChatEffectEvent;
      expect(chatEvent.effectName, 'balloons');
    });

    test(
      'missing effect field in outgoing event falls back to empty string',
      () {
        final outgoing = EffectRoomEvent(
          senderDid: 'did:test:alice',
          effect: '',
        );

        final chatEvent = outgoing.toChatEvent() as ChatEffectEvent;
        expect(chatEvent.effectName, '');
      },
    );
  });
}
