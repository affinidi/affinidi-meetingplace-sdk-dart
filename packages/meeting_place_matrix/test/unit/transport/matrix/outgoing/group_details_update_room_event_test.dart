import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/src/transport/matrix/outgoing/group_details_update_room_event.dart';
import 'package:test/test.dart';

void main() {
  group('GroupDetailsUpdateRoomEvent', () {
    final ownerCard = ContactCard(
      did: 'did:test:alice',
      type: 'human',
      contactInfo: {'n': 'Alice'},
    );

    Group buildGroup() => Group(
      id: 'group-1',
      did: 'did:test:group',
      offerLink: 'offer://test',
      created: DateTime.utc(2026, 1, 1),
      ownerDid: 'did:test:alice',
      publicKey: 'pubkey',
      members: [
        GroupMember.admin(
          did: 'did:test:alice',
          publicKey: 'pubkey',
          contactCard: ownerCard,
        ),
      ],
    );

    test('uses the com.affinidi wire type', () {
      final event = GroupDetailsUpdateRoomEvent(
        senderDid: 'did:test:alice',
        group: buildGroup(),
      );
      expect(event.type, 'com.affinidi.chat.group-details-update');
    });

    test('content carries group identifiers and members list', () {
      final event = GroupDetailsUpdateRoomEvent(
        senderDid: 'did:test:alice',
        group: buildGroup(),
      );
      expect(event.content['group_id'], 'group-1');
      expect(event.content['group_did'], 'did:test:group');
      expect(event.content['members'], isA<List>());
      expect((event.content['members'] as List).length, 1);
    });
  });
}
