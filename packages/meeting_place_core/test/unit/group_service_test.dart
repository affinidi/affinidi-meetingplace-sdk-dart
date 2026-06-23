import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    as cp;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/channel/channel_service.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:meeting_place_core/src/service/connection_offer/connection_offer_service.dart';
import 'package:meeting_place_core/src/service/connection_service.dart';
import 'package:meeting_place_core/src/service/group.dart';
import 'package:meeting_place_core/src/service/group/group_exception.dart';
import 'package:meeting_place_core/src/service/identity/identity_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../fixtures/contact_card_fixture.dart';

class _MockWallet extends Mock implements Wallet {}

class _MockConnectionManager extends Mock implements ConnectionManager {}

class _MockConnectionOfferRepository extends Mock
    implements ConnectionOfferRepository {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockKeyRepository extends Mock implements KeyRepository {}

class _MockChannelService extends Mock implements ChannelService {}

class _MockConnectionOfferService extends Mock
    implements ConnectionOfferService {}

class _MockConnectionService extends Mock implements ConnectionService {}

class _MockIdentityService extends Mock implements IdentityService {}

class _MockControlPlaneSDK extends Mock implements cp.ControlPlaneSDK {}

class _MockMediatorSDK extends Mock implements MeetingPlaceMediatorSDK {}

class _MockMatrixService extends Mock implements MatrixService {}

class _MockDidResolver extends Mock implements DidResolver {}

GroupMember _ownerMember(String did) => GroupMember.admin(
  did: did,
  publicKey: 'pk-$did',
  contactCard: ContactCardFixture.getContactCardFixture(did: did),
);

GroupMember _member(String did) => GroupMember(
  did: did,
  publicKey: 'pk-$did',
  dateAdded: DateTime.utc(2026, 1, 1),
  status: GroupMemberStatus.approved,
  membershipType: GroupMembershipType.member,
  contactCard: ContactCardFixture.getContactCardFixture(did: did),
);

Group _group({
  String? ownerDid = 'did:test:alice',
  String? publicKey = 'group-pk',
  List<GroupMember>? members,
}) => Group(
  id: 'group-1',
  did: 'did:test:group',
  offerLink: 'offer://test',
  created: DateTime.utc(2026, 1, 1),
  ownerDid: ownerDid,
  publicKey: publicKey,
  members: members ?? [_ownerMember('did:test:alice'), _member('did:test:bob')],
);

void main() {
  group('GroupService.removeMember validation', () {
    late _MockGroupRepository groupRepository;
    late GroupService service;

    setUp(() {
      groupRepository = _MockGroupRepository();
      service = GroupService(
        wallet: _MockWallet(),
        connectionManager: _MockConnectionManager(),
        connectionOfferRepository: _MockConnectionOfferRepository(),
        groupRepository: groupRepository,
        keyRepository: _MockKeyRepository(),
        channelService: _MockChannelService(),
        offerService: _MockConnectionOfferService(),
        connectionService: _MockConnectionService(),
        identityService: _MockIdentityService(),
        controlPlaneSDK: _MockControlPlaneSDK(),
        mediatorSDK: _MockMediatorSDK(),
        matrixService: _MockMatrixService(),
        didResolver: _MockDidResolver(),
      );
    });

    test('throws groupNotFoundError when the group does not exist', () async {
      when(
        () => groupRepository.getGroupById('missing'),
      ).thenAnswer((_) async => null);

      await expectLater(
        () =>
            service.removeMember(groupId: 'missing', memberDid: 'did:test:bob'),
        throwsA(
          isA<GroupException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceCoreSDKErrorCode.groupNotFoundError,
          ),
        ),
      );
    });

    test('throws groupNotFoundError when ownerDid is null', () async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => _group(ownerDid: null));

      await expectLater(
        () =>
            service.removeMember(groupId: 'group-1', memberDid: 'did:test:bob'),
        throwsA(
          isA<GroupException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceCoreSDKErrorCode.groupNotFoundError,
          ),
        ),
      );
    });

    test('throws groupNotFoundError when publicKey is null', () async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => _group(publicKey: null));

      await expectLater(
        () =>
            service.removeMember(groupId: 'group-1', memberDid: 'did:test:bob'),
        throwsA(
          isA<GroupException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceCoreSDKErrorCode.groupNotFoundError,
          ),
        ),
      );
    });

    test('throws cannotRemoveOwner when target is the owner', () async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => _group());

      await expectLater(
        () => service.removeMember(
          groupId: 'group-1',
          memberDid: 'did:test:alice',
        ),
        throwsA(
          isA<GroupException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceCoreSDKErrorCode.groupCannotRemoveOwnerError,
          ),
        ),
      );
    });

    test('throws memberDoesNotBelongToGroupError when target is not a '
        'member', () async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => _group());

      await expectLater(
        () =>
            service.removeMember(groupId: 'group-1', memberDid: 'did:test:eve'),
        throwsA(
          isA<GroupException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceCoreSDKErrorCode.groupMemberDoesNotBelongToGroupError,
          ),
        ),
      );
    });
  });
}
