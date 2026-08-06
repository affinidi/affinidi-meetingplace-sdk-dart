// ignore_for_file: invalid_use_of_protected_member

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/src/chat/group/group_matrix_chat_sdk.dart';
import 'package:meeting_place_matrix/src/chat/group/group_room_event_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../meeting_place_matrix.dart';

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

GroupMatrixChatSDK _buildSdk(
  Group group, {
  required MeetingPlaceCoreSDK coreSDK,
}) => GroupMatrixChatSDK(
  coreSDK: coreSDK,
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
    test(
      'resolves kicked member DID from Matrix membership state key',
      () async {
        const serverName = 'server';
        final coreSDK = _MockCoreSDK();
        final router = GroupRoomEventRouter(
          chatSDK: _buildSdk(_group(), coreSDK: coreSDK),
        );
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

        expect(await router.resolveTargetDid(event), 'did:test:bob');
        verifyNever(() => coreSDK.getGroupById(any()));
      },
    );

    test('returns null when the state key matches no member in-memory or '
        'persisted', () async {
      const serverName = 'server';
      final group = _group();
      final coreSDK = _MockCoreSDK();
      when(() => coreSDK.getGroupById(any())).thenAnswer((_) async => group);
      final router = GroupRoomEventRouter(
        chatSDK: _buildSdk(group, coreSDK: coreSDK),
      );
      final event = MatrixRoomEvent(
        id: 'evt-2',
        type: matrix.EventTypes.RoomMember,
        senderDid: 'did:test:alice',
        roomId: '!room:$serverName',
        content: const {'membership': 'join'},
        timestamp: DateTime.utc(2026, 1, 1),
        stateKey: deriveMatrixUserId('did:test:eve', serverName),
      );

      expect(await router.resolveTargetDid(event), isNull);
    });

    test('does not query the persisted store for a non-join event that '
        'misses in-memory', () async {
      const serverName = 'server';
      final coreSDK = _MockCoreSDK();
      final router = GroupRoomEventRouter(
        chatSDK: _buildSdk(_group(), coreSDK: coreSDK),
      );
      final event = MatrixRoomEvent(
        id: 'evt-4',
        type: matrix.EventTypes.RoomMember,
        senderDid: 'did:test:alice',
        roomId: '!room:$serverName',
        content: const {'membership': 'leave'},
        timestamp: DateTime.utc(2026, 1, 1),
        stateKey: deriveMatrixUserId('did:test:eve', serverName),
      );

      expect(await router.resolveTargetDid(event), isNull);
      verifyNever(() => coreSDK.getGroupById(any()));
    });

    test('falls back to the persisted group when the in-memory snapshot is '
        'stale', () async {
      const serverName = 'server';
      final staleGroup = _group();
      final persistedGroup = Group(
        id: staleGroup.id,
        did: staleGroup.did,
        offerLink: staleGroup.offerLink,
        created: staleGroup.created,
        ownerDid: staleGroup.ownerDid,
        publicKey: staleGroup.publicKey,
        members: [
          ...staleGroup.members,
          GroupMember(
            did: 'did:test:charlie',
            publicKey: 'pk-charlie',
            dateAdded: DateTime.utc(2026, 1, 1),
            status: GroupMemberStatus.approved,
            membershipType: GroupMembershipType.member,
            contactCard: _card('did:test:charlie'),
          ),
        ],
      );
      final coreSDK = _MockCoreSDK();
      when(
        () => coreSDK.getGroupById(staleGroup.id),
      ).thenAnswer((_) async => persistedGroup);
      final router = GroupRoomEventRouter(
        chatSDK: _buildSdk(staleGroup, coreSDK: coreSDK),
      );
      final event = MatrixRoomEvent(
        id: 'evt-3',
        type: matrix.EventTypes.RoomMember,
        senderDid: 'did:test:alice',
        roomId: '!room:$serverName',
        content: const {'membership': 'join'},
        timestamp: DateTime.utc(2026, 1, 1),
        stateKey: deriveMatrixUserId('did:test:charlie', serverName),
      );

      expect(await router.resolveTargetDid(event), 'did:test:charlie');
      verify(() => coreSDK.getGroupById(staleGroup.id)).called(1);
    });
  });
}
