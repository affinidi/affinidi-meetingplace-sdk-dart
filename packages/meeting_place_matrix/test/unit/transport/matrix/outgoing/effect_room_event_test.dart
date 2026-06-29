import 'package:meeting_place_matrix/src/transport/matrix/outgoing/effect_room_event.dart';
import 'package:test/test.dart';

void main() {
  group('EffectRoomEvent', () {
    test('uses the com.affinidi wire type', () {
      final event = EffectRoomEvent(
        senderDid: 'did:test:alice',
        effect: 'confetti',
      );
      expect(event.type, 'com.affinidi.chat.effect');
    });

    test('puts effect name in content', () {
      final event = EffectRoomEvent(
        senderDid: 'did:test:alice',
        effect: 'balloons',
      );
      expect(event.content, {'effect': 'balloons'});
    });
  });
}
