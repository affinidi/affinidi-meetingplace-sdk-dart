import 'package:meeting_place_matrix/src/transport/matrix/outgoing/profile_hash_room_event.dart';
import 'package:test/test.dart';

void main() {
  group('ProfileHashRoomEvent', () {
    test('uses the com.affinidi wire type', () {
      final event = ProfileHashRoomEvent(
        senderDid: 'did:test:alice',
        profileHash: 'hash-abc',
      );
      expect(event.type, 'com.affinidi.chat.profile-hash');
    });

    test('puts profile_hash in content', () {
      final event = ProfileHashRoomEvent(
        senderDid: 'did:test:alice',
        profileHash: 'hash-abc',
      );
      expect(event.content, {'profile_hash': 'hash-abc'});
    });
  });
}
