import 'dart:convert';

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
import 'package:proxy_recrypt/proxy_recrypt.dart' as recrypt;
import 'package:ssi/ssi.dart' hide KeyPair;
import 'package:test/test.dart';

import '../fixtures/contact_card_fixture.dart';
import 'event_handler/mocks/mocks.dart';

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
    registerFallbackValue(FakeChannel());
    registerFallbackValue(FakePlainTextMessage());
    registerFallbackValue(FakeDidDocument());
    registerFallbackValue(_group());
    registerFallbackValue(
      cp.GroupAddMemberCommand(
        mnemonic: '',
        groupId: '',
        memberDid: '',
        acceptOfferDid: '',
        offerLink: '',
        publicKey: '',
        reencryptionKey: '',
      ),
    );
    // updateMemberStatus and verify calls use any() on GroupMemberStatus.
    registerFallbackValue(GroupMemberStatus.pendingApproval);
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

  // ---------------------------------------------------------------------------
  // approveMembershipRequest — atomic status update
  // ---------------------------------------------------------------------------
  // These tests prove that approveMembershipRequest uses updateMemberStatus
  // (single-row atomic write) instead of the old updateGroup (full replace),
  // which was the root cause of the lost-update: the full-replace writer would
  // silently drop members added by a concurrent InvitationGroupAcceptedHandler.
  // ---------------------------------------------------------------------------

  group('GroupService.approveMembershipRequest — atomic status update', () {
    late _MockGroupRepository groupRepository;
    late _MockConnectionManager connectionManager;
    late _MockConnectionOfferRepository connectionOfferRepository;
    late _MockIdentityService identityService;
    late _MockChannelService channelService;
    late _MockMeetingPlaceTransport channelTransport;
    late _MockMediatorSDK mediatorSDK;
    late _MockKeyRepository keyRepository;
    late _MockControlPlaneSDK controlPlaneSDK;
    late _MockDidResolver didResolver;
    late GroupService service;

    const approveOfferLink = 'offer://approve-test';
    const approveMemberDid = 'did:test:bob-approve';
    const approveGroupId = 'group-approve-1';
    const approveGroupDid = 'did:test:group-approve';
    const approveOwnerDid = 'did:test:alice-approve';
    const approveMediatorDid = 'did:test:mediator-approve';
    const approvePublishOfferDid = 'did:test:publish-approve';
    const approveAcceptOfferDid = 'did:test:accept-approve';

    setUp(() {
      groupRepository = _MockGroupRepository();
      connectionManager = _MockConnectionManager();
      connectionOfferRepository = _MockConnectionOfferRepository();
      identityService = _MockIdentityService();
      channelService = _MockChannelService();
      channelTransport = _MockMeetingPlaceTransport();
      mediatorSDK = _MockMediatorSDK();
      keyRepository = _MockKeyRepository();
      controlPlaneSDK = _MockControlPlaneSDK();
      didResolver = _MockDidResolver();

      service = GroupService(
        wallet: _MockWallet(),
        connectionManager: connectionManager,
        connectionOfferRepository: connectionOfferRepository,
        groupRepository: groupRepository,
        keyRepository: keyRepository,
        channelService: channelService,
        offerService: _MockConnectionOfferService(),
        connectionService: _MockConnectionService(),
        identityService: identityService,
        controlPlaneSDK: controlPlaneSDK,
        mediatorSDK: mediatorSDK,
        channelTransport: channelTransport,
        didResolver: didResolver,
      );
    });

    test('calls updateMemberStatus (not updateGroup) so concurrent handler '
        'adds are never clobbered by a full member-list replace', () async {
      // Generate real proxy_recrypt keys so generateMemberReEncryptionKey
      // (called inside approveMembershipRequest) doesn't throw.
      final r = recrypt.Recrypt();
      final groupKeyPair = r.generateKeyPair();
      final memberKeyPair = r.generateKeyPair();
      // The service stores
      // privateKeyBytes = base64.decode(privateKey.toBase64()) and later does
      // base64.encode(bytes) → fromBase64 to reconstruct.
      final groupPrivateBytes = base64.decode(
        groupKeyPair.privateKey.toBase64(),
      );

      final pendingMember = GroupMember(
        did: approveMemberDid,
        publicKey: memberKeyPair.publicKey.toBase64(), // valid recrypt pubkey
        dateAdded: DateTime.utc(2026, 1, 1),
        status: GroupMemberStatus.pendingApproval,
        membershipType: GroupMembershipType.member,
        contactCard: ContactCardFixture.getContactCardFixture(
          did: approveMemberDid,
        ),
      );

      final group = Group(
        id: approveGroupId,
        did: approveGroupDid,
        offerLink: approveOfferLink,
        created: DateTime.utc(2026, 1, 1),
        ownerDid: approveOwnerDid,
        publicKey: 'group-pk',
        members: [
          _ownerMember(approveOwnerDid),
          pendingMember,
          // Extra member simulating a concurrent InvitationGroupAcceptedHandler
          // add. With the old full-replace, this would be dropped.
          GroupMember(
            did: 'did:test:concurrent-joiner',
            publicKey: 'pk-concurrent',
            dateAdded: DateTime.utc(2026, 1, 1),
            status: GroupMemberStatus.pendingApproval,
            membershipType: GroupMembershipType.member,
            contactCard: ContactCardFixture.getContactCardFixture(
              did: 'did:test:concurrent-joiner',
            ),
          ),
        ],
      );

      final channel = Channel(
        offerLink: approveOfferLink,
        publishOfferDid: approvePublishOfferDid,
        acceptOfferDid: approveAcceptOfferDid,
        mediatorDid: approveMediatorDid,
        status: ChannelStatus.waitingForApproval,
        contactCard: ContactCardFixture.getContactCardFixture(),
        otherPartyContactCard: ContactCardFixture.getContactCardFixture(
          did: approveMemberDid,
        ),
        type: ChannelType.group,
        isConnectionInitiator: true,
        permanentChannelDid: approveOwnerDid,
        otherPartyPermanentChannelDid: approveMemberDid,
      );

      final ownerDidManager = _MockDidManager();
      final memberDidDocument = _MockDidDocument(approveMemberDid);

      // Both getGroupByOfferLink calls (initial read + post-update fresh read)
      // return the same group for simplicity; the test is about which write
      // method is called, not about the inauguration message contents.
      when(
        () => groupRepository.getGroupByOfferLink(approveOfferLink),
      ).thenAnswer((_) async => group);

      when(
        () => connectionOfferRepository.getConnectionOfferByOfferLink(
          approveOfferLink,
        ),
      ).thenAnswer(
        (_) async => ConnectionOffer(
          offerName: 'Group',
          offerLink: approveOfferLink,
          mnemonic: 'test-mnemonic',
          oobInvitationMessage: '',
          status: ConnectionOfferStatus.accepted,
          publishOfferDid: approvePublishOfferDid,
          acceptOfferDid: approveAcceptOfferDid,
          mediatorDid: approveMediatorDid,
          type: ConnectionOfferType.meetingPlaceInvitation,
          contactCard: ContactCardFixture.getContactCardFixture(),
          ownedByMe: true,
          createdAt: DateTime.utc(2026, 1, 1),
          transport: ChannelTransport.matrix,
        ),
      );

      when(
        () => didResolver.resolveDid(approveMemberDid),
      ).thenAnswer((_) async => memberDidDocument);

      // _allowMemberToMessageGroupAdmin: getDidManagerForDid(wallet, ownerDid)
      when(
        () => connectionManager.getDidManagerForDid(any(), approveOwnerDid),
      ).thenAnswer((_) async => ownerDidManager);

      when(
        () => mediatorSDK.updateAcl(
          ownerDidManager: any(named: 'ownerDidManager'),
          acl: any(named: 'acl'),
          mediatorDid: any(named: 'mediatorDid'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => identityService.getPermanentIdentity(any(), approveOwnerDid),
      ).thenAnswer(
        (_) async => PermanentIdentity(
          didManager: ownerDidManager,
          didDocument: memberDidDocument,
        ),
      );

      final groupChannel = Channel(
        offerLink: approveOfferLink,
        publishOfferDid: approvePublishOfferDid,
        mediatorDid: approveMediatorDid,
        status: ChannelStatus.inaugurated,
        isConnectionInitiator: true,
        contactCard: ContactCardFixture.getContactCardFixture(),
        type: ChannelType.group,
        permanentChannelDid: approveOwnerDid,
        otherPartyPermanentChannelDid: approveGroupDid,
      );
      when(
        () => channelService.findChannelByOtherPartyPermanentChannelDid(
          approveGroupDid,
        ),
      ).thenAnswer((_) async => groupChannel);

      when(
        () => channelTransport.inviteToChannel(
          channel: any(named: 'channel'),
          participantDid: any(named: 'participantDid'),
          didManager: any(named: 'didManager'),
        ),
      ).thenAnswer((_) async {});

      // senderDid: getDidManagerForDid(wallet, publishOfferDid)
      when(
        () => connectionManager.getDidManagerForDid(
          any(),
          approvePublishOfferDid,
        ),
      ).thenAnswer((_) async => ownerDidManager);

      // generateMemberReEncryptionKey reads the group private key
      when(() => keyRepository.getKeyPair(approveGroupDid)).thenAnswer(
        (_) async => KeyPair(
          privateKeyBytes: groupPrivateBytes,
          publicKeyBytes: base64.decode(groupKeyPair.publicKey.toBase64()),
        ),
      );

      when(
        () => groupRepository.updateMemberStatus(any(), any(), any()),
      ).thenAnswer((_) async {});

      when(
        () => mediatorSDK.sendMessage(
          any(),
          senderDidManager: any(named: 'senderDidManager'),
          recipientDidDocument: any(named: 'recipientDidDocument'),
          mediatorDid: any(named: 'mediatorDid'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => controlPlaneSDK.execute<cp.GroupAddMemberCommandOutput>(any()),
      ).thenAnswer((_) async => FakeGroupAddMemberCommandOutput());

      final result = await service.approveMembershipRequest(channel: channel);

      // The method completes and returns the channel it was given.
      expect(result, same(channel));

      // KEY ASSERTION: atomic single-row update — no full member-list replace.
      verify(
        () => groupRepository.updateMemberStatus(
          approveGroupId,
          approveMemberDid,
          GroupMemberStatus.approved,
        ),
      ).called(1);

      // updateGroup must NOT be called during approve — using it would silently
      // drop members that a concurrent InvitationGroupAcceptedHandler added
      // between the initial getGroupByOfferLink read and this write.
      verifyNever(() => groupRepository.updateGroup(any()));

      // Two reads must be issued: one at the start of the method to resolve
      // member/group data, and one after the atomic update to build the
      // GroupMemberInauguration message from the freshest list.
      verify(
        () => groupRepository.getGroupByOfferLink(approveOfferLink),
      ).called(2);
    });
  });

  group('GroupService.rejectMembershipRequest — atomic remove', () {
    late _MockGroupRepository groupRepository;
    late GroupService service;

    const rejectOfferLink = 'offer://reject-test';
    const rejectMemberDid = 'did:test:bob-reject';
    const rejectGroupId = 'group-reject-1';

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

    test('removes the member via removeMember (not updateGroup)', () async {
      final group = _group(
        members: [_ownerMember('did:test:alice'), _member(rejectMemberDid)],
      ).copyWith(id: rejectGroupId, offerLink: rejectOfferLink);

      when(
        () => groupRepository.getGroupByOfferLink(rejectOfferLink),
      ).thenAnswer((_) async => group);
      when(
        () => groupRepository.removeMember(any(), any()),
      ).thenAnswer((_) async {});

      final channel = Channel(
        offerLink: rejectOfferLink,
        publishOfferDid: 'did:test:publish',
        mediatorDid: 'did:test:mediator',
        status: ChannelStatus.waitingForApproval,
        contactCard: ContactCardFixture.getContactCardFixture(),
        type: ChannelType.group,
        isConnectionInitiator: true,
        permanentChannelDid: 'did:test:alice',
        otherPartyPermanentChannelDid: rejectMemberDid,
      );

      final result = await service.rejectMembershipRequest(channel);

      // KEY ASSERTION: atomic single-row delete, never a full-list replace.
      verify(
        () => groupRepository.removeMember(rejectGroupId, rejectMemberDid),
      ).called(1);
      verifyNever(() => groupRepository.updateGroup(any()));

      // The returned group no longer contains the rejected member.
      expect(result.members.any((m) => m.did == rejectMemberDid), isFalse);
    });
  });
}
