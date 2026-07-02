import 'package:meeting_place_matrix/src/transport/matrix/outgoing/contact_details_update_room_event.dart';
import 'package:test/test.dart';

void main() {
  group('ContactDetailsUpdateRoomEvent', () {
    final profile = <String, dynamic>{
      'did': 'did:test:alice',
      'type': 'human',
      'contactInfo': {'n': 'Alice'},
    };

    test('uses the com.affinidi wire type', () {
      final event = ContactDetailsUpdateRoomEvent(
        senderDid: 'did:test:alice',
        profileDetails: profile,
      );
      expect(event.type, 'com.affinidi.chat.contact-details-update');
    });

    test('nests profileDetails under the profileDetails key', () {
      final event = ContactDetailsUpdateRoomEvent(
        senderDid: 'did:test:alice',
        profileDetails: profile,
      );
      expect(event.content, {'profileDetails': profile});
    });
  });
}
