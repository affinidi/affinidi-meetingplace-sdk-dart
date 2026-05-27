import 'package:meeting_place_chat/src/transport/matrix/outgoing/profile_request_room_event.dart';
import 'package:test/test.dart';

void main() {
  group('ProfileRequestRoomEvent', () {
    test('uses the com.affinidi wire type', () {
      final event = ProfileRequestRoomEvent(
        senderDid: 'did:test:alice',
        roomId: '!room:server',
        profileHash: 'hash-abc',
      );
      expect(event.type, 'com.affinidi.chat.profile-request');
    });

    test('puts profile_hash in content', () {
      final event = ProfileRequestRoomEvent(
        senderDid: 'did:test:alice',
        roomId: '!room:server',
        profileHash: 'hash-abc',
      );
      expect(event.content, {'profile_hash': 'hash-abc'});
    });

    test('forwards senderDid and roomId to the base class', () {
      final event = ProfileRequestRoomEvent(
        senderDid: 'did:test:alice',
        roomId: '!room:server',
        profileHash: 'hash-abc',
      );
      expect(event.senderDid, 'did:test:alice');
      expect(event.roomId, '!room:server');
    });
  });
}
