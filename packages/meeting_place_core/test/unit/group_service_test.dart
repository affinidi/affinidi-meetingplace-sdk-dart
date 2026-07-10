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
import 'package:meeting_place_core/src/service/identity/model/permanent_identity.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
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

class _MockMeetingPlaceTransport extends Mock
    implements MeetingPlaceTransport {}

class _MockDidResolver extends Mock implements DidResolver {}

class _MockDidManager extends Mock implements DidManager {}

class _FakeAclBody extends Fake implements AclBody {}

class _FakeChannel extends Fake implements Channel {}

class _MockDidDocument extends Mock implements DidDocument {
  _MockDidDocument(this._id);
  final String _id;

  @override
  String get id => _id;
}

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
  setUpAll(() {
    registerFallbackValue(_MockWallet());
    registerFallbackValue(_MockDidManager());
    registerFallbackValue(_FakeAclBody());
    registerFallbackValue(_FakeChannel());
  });

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
        channelTransport: _MockMeetingPlaceTransport(),
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

  group('GroupService.leaveGroup - _leaveGroupAsMember error handling', () {
    late _MockGroupRepository groupRepository;
    late _MockMeetingPlaceTransport meetingPlaceTransport;
    late _MockIdentityService identityService;
    late _MockChannelService channelService;
    late _MockConnectionOfferRepository connectionOfferRepository;
    late _MockMediatorSDK mediatorSDK;
    late GroupService service;

    final memberDidManager = _MockDidManager();
    final memberDidDocument = _MockDidDocument('did:test:bob');

    setUp(() {
      groupRepository = _MockGroupRepository();
      meetingPlaceTransport = _MockMeetingPlaceTransport();
      identityService = _MockIdentityService();
      channelService = _MockChannelService();
      connectionOfferRepository = _MockConnectionOfferRepository();
      mediatorSDK = _MockMediatorSDK();

      service = GroupService(
        wallet: _MockWallet(),
        connectionManager: _MockConnectionManager(),
        connectionOfferRepository: connectionOfferRepository,
        groupRepository: groupRepository,
        keyRepository: _MockKeyRepository(),
        channelService: channelService,
        offerService: _MockConnectionOfferService(),
        connectionService: _MockConnectionService(),
        identityService: identityService,
        controlPlaneSDK: _MockControlPlaneSDK(),
        mediatorSDK: mediatorSDK,
        channelTransport: meetingPlaceTransport,
        didResolver: _MockDidResolver(),
      );
    });

    test('completes without throwing when leaveRoom throws', () async {
      final grp = _group();
      final channel = Channel(
        offerLink: 'offer://test',
        publishOfferDid: 'did:test:publish',
        mediatorDid: 'did:test:mediator',
        status: ChannelStatus.approved,
        contactCard: ContactCardFixture.getContactCardFixture(),
        type: ChannelType.group,
        isConnectionInitiator: false,
        permanentChannelDid: 'did:test:bob',
      );

      when(
        () => groupRepository.getGroupByOfferLink('offer://test'),
      ).thenAnswer((_) async => grp);

      when(
        () => identityService.getPermanentIdentity(any(), 'did:test:bob'),
      ).thenAnswer(
        (_) async => PermanentIdentity(
          didManager: memberDidManager,
          didDocument: memberDidDocument,
        ),
      );

      when(
        () => meetingPlaceTransport.leaveChannel(
          channel: any(named: 'channel'),
          didManager: memberDidManager,
        ),
      ).thenThrow(Exception('Server unavailable'));

      when(
        () => connectionOfferRepository.getConnectionOfferByOfferLink(
          'offer://test',
        ),
      ).thenAnswer((_) async => null);

      when(
        () => channelService.deleteChannel(channel),
      ).thenAnswer((_) async {});

      when(
        () => mediatorSDK.updateAcl(
          ownerDidManager: memberDidManager,
          mediatorDid: 'did:test:mediator',
          acl: any(named: 'acl'),
        ),
      ).thenAnswer((_) async {});

      when(
        memberDidManager.getDidDocument,
      ).thenAnswer((_) async => memberDidDocument);

      when(() => groupRepository.removeGroup(grp)).thenAnswer((_) async {});

      await expectLater(service.leaveGroup(channel), completes);

      verify(
        () => meetingPlaceTransport.leaveChannel(
          channel: any(named: 'channel'),
          didManager: memberDidManager,
        ),
      ).called(1);
    });
  });
}
