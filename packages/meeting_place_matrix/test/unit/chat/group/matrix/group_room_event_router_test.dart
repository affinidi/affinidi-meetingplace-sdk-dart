// ignore_for_file: invalid_use_of_protected_member

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/src/chat/group/group_room_event_router.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

ContactCard _card(String did) =>
    ContactCard(did: did, type: 'human', contactInfo: {'n': did});

Group _group() => Group(
  id: 'group-1',
  did: 'did:test:group',
  offerLink: 'offer://test',
  created: DateTime.utc(2026, 1, 1),
  ownerDid: 'did:test:alice',
  publicKey: 'pk',
  members: [
    GroupMember.admin(
      did: 'did:test:alice',
      publicKey: 'pk-alice',
      contactCard: _card('did:test:alice'),
    ),
    GroupMember(
      did: 'did:test:bob',
      publicKey: 'pk-bob',
      dateAdded: DateTime.utc(2026, 1, 1),
      status: GroupMemberStatus.approved,
      membershipType: GroupMembershipType.member,
      contactCard: _card('did:test:bob'),
    ),
  ],
);

GroupMatrixChatSDK _buildSdk(Group group) => GroupMatrixChatSDK(
  coreSDK: _MockCoreSDK(),
  did: 'did:test:alice',
  otherPartyDid: group.did,
  mediatorDid: 'did:test:mediator',
  chatRepository: _MockChatRepository(),
  options: MeetingPlaceChatSDKOptions(
    chatPresenceSendInterval: const Duration(hours: 1),
  ),
  group: group,
);

void main() {
  group('GroupRoomEventRouter', () {
    test('resolves kicked member DID from Matrix membership state key', () {
      const serverName = 'server';
      final router = GroupRoomEventRouter(chatSDK: _buildSdk(_group()));
      final event = MatrixRoomEvent(
        id: 'evt-1',
        type: matrix.EventTypes.RoomMember,
        senderDid: 'did:test:alice',
        roomId: '!room:$serverName',
        content: const {'membership': 'leave'},
        timestamp: DateTime.utc(2026, 1, 1),
        isReplay: true,
        stateKey: deriveMatrixUserId('did:test:bob', serverName),
      );

      expect(router.resolveTargetDid(event), 'did:test:bob');
    });

    test('returns null when membership state key does not match a member', () {
      const serverName = 'server';
      final router = GroupRoomEventRouter(chatSDK: _buildSdk(_group()));
      final event = MatrixRoomEvent(
        id: 'evt-2',
        type: matrix.EventTypes.RoomMember,
        senderDid: 'did:test:alice',
        roomId: '!room:$serverName',
        content: const {'membership': 'leave'},
        timestamp: DateTime.utc(2026, 1, 1),
        stateKey: deriveMatrixUserId('did:test:eve', serverName),
      );

      expect(router.resolveTargetDid(event), isNull);
    });
  });
}
