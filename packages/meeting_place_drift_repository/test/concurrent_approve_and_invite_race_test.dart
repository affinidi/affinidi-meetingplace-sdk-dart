/// Regression test: concurrent approve + invitation-accept both persist
/// (lost-update race, real Drift repository).
///
/// WHY this test exists
/// --------------------
/// The old code used a full-list read → mutate-in-memory → updateGroup
/// (full-replace) in BOTH `GroupService.approveMembershipRequest`
/// (runs outside the serialised event queue) AND
/// `InvitationGroupAcceptedEventHandler.process` (runs inside it).
/// When they interleaved the slower writer clobbered the other
/// writer's member, producing a
/// "group_member_does_not_belong_to_group_error"
/// on the next Approve.
///
/// The fix replaced both paths with atomic single-row ops:
///   • `updateMemberStatus`  – approve changes exactly one row's status
///   • `addMemberIfAbsent`   – handler inserts exactly one new row (idempotent)
///
/// This test drives the REAL production code paths (GroupService +
/// InvitationGroupAcceptedEventHandler) against a REAL in-memory
/// GroupsRepositoryDrift backed by a NativeDatabase.memory() SQLite database.
/// All non-persistence collaborators (messaging, DID resolution, crypto
/// key-store look-ups, control-plane, mediator transport) are stubbed because
/// they are not part of the persistence contract under test.
///
/// Determinism note
/// ----------------
/// SQLite serialises concurrent writes; `updateMemberStatus` and
/// `addMemberIfAbsent` target different rows, so they cannot dead-lock or
/// clobber each other regardless of scheduling order. The `Future.wait` below
/// exploits Dart's cooperative scheduler: both coroutines are started before
/// either yields at an `await`, so they genuinely interleave at every await
/// point. The test is therefore not flaky.
///
/// Discriminating note
/// -------------------
/// If either service path reverted to `updateGroup` (full-replace), this test
/// would fail because the concurrent full-replace would drop either Bob or
/// Carol depending on which writer landed last.

library;

import 'dart:io';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    as cp;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/event_handler/invitation_accepted_group_event_handler.dart';
import 'package:meeting_place_core/src/service/channel/channel_service.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:meeting_place_core/src/service/connection_offer/connection_offer_service.dart';
import 'package:meeting_place_core/src/service/connection_service.dart';
import 'package:meeting_place_core/src/service/group.dart';
import 'package:meeting_place_core/src/service/identity/identity_service.dart';
import 'package:meeting_place_core/src/service/identity/model/permanent_identity.dart';
import 'package:meeting_place_core/src/service/mediator/fetch_messages_options.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_service.dart';
// Import only the two concrete Drift types needed, bypassing the barrel export
// that re-exports Drift-generated table classes with the same names as core
// entities (Channel, GroupMember, ConnectionOffer …).
// Alias the database import to avoid the Drift-generated GroupMember table
// class clashing with meeting_place_core's GroupMember entity.
import 'package:meeting_place_drift_repository/src/repositories/group_repository/groups_database.dart'
    as drift_db;
import 'package:meeting_place_drift_repository/src/repositories/group_repository/groups_repository_drift.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart' hide KeyPair;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Minimal stubs — only non-persistence collaborators are faked.
// ---------------------------------------------------------------------------

class _MockWallet extends Mock implements Wallet {}

class _MockConnectionManager extends Mock implements ConnectionManager {}

class _MockConnectionOfferRepository extends Mock
    implements ConnectionOfferRepository {}

class _MockChannelService extends Mock implements ChannelService {}

class _MockConnectionOfferService extends Mock
    implements ConnectionOfferService {}

class _MockConnectionService extends Mock implements ConnectionService {}

class _MockIdentityService extends Mock implements IdentityService {}

class _MockMeetingPlaceControlPlaneSDK extends Mock
    implements cp.MeetingPlaceControlPlaneSDK {}

class _MockMediatorSDK extends Mock implements MeetingPlaceMediatorSDK {}

class _MockMeetingPlaceTransport extends Mock
    implements MeetingPlaceTransport {}

class _MockDidResolver extends Mock implements DidResolver {}

class _MockMediatorService extends Mock implements MediatorService {}

/// Concrete DidManager stub whose `getDidDocument()` returns a valid
/// [DidDocument] — required because `BaseEventHandler.processEvent`
/// calls `didManager.getDidDocument()` to log the DID.
class _StubDidManager extends Mock implements DidManager {
  _StubDidManager(this._did);

  final String _did;

  @override
  Future<DidDocument> getDidDocument() async => DidDocument.create(id: _did);
}

class _FakeChannel extends Fake implements Channel {}

class _FakePlainTextMessage extends Fake implements PlainTextMessage {}

class _FakeGroupAddMemberCommandOutput extends Fake
    implements cp.GroupAddMemberCommandOutput {}

class _FakeFetchMessagesOptions extends Fake implements FetchMessagesOptions {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

drift_db.GroupsDatabase _inMemoryGroupsDatabase() => drift_db.GroupsDatabase(
  databaseName: 'race_test.db',
  passphrase: 'test-passphrase',
  directory: Directory.systemTemp,
  inMemory: true,
);

ContactCard _card(String did) => ContactCard(
  did: did,
  type: 'individual',
  contactInfo: const {'fullName': 'Test User'},
);

PlainTextMessage _buildAcceptanceMessage({
  required String from,
  required String to,
  required String channelDid,
  required ContactCard contactCard,
}) {
  final msg = InvitationAcceptanceGroup.create(
    from: from,
    to: [to],
    parentThreadId: const Uuid().v4(),
    channelDid: channelDid,
    contactCard: contactCard,
  );
  return msg.toPlainTextMessage();
}

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(_MockWallet());
    registerFallbackValue(_StubDidManager('did:fallback'));
    // AclBody is not re-exported by meeting_place_core; use a concrete subtype
    // (AccessListAdd) as the fallback for any(named: 'acl') matchers.
    registerFallbackValue(
      AccessListAdd(ownerDid: 'did:fallback', granteeDids: []),
    );
    registerFallbackValue(_FakeChannel());
    registerFallbackValue(_FakePlainTextMessage());
    registerFallbackValue(
      MediatorMessageRequest(
        message: _FakePlainTextMessage(),
        senderDidManager: _StubDidManager('did:fallback'),
        recipientDidDocument: DidDocument.create(id: 'did:fallback'),
      ),
    );
    registerFallbackValue(_FakeGroupAddMemberCommandOutput());
    registerFallbackValue(_FakeFetchMessagesOptions());
    registerFallbackValue(DidDocument.create(id: 'did:fallback'));
    registerFallbackValue(GroupMemberStatus.pendingApproval);
    registerFallbackValue(
      GroupMember.pendingMember(
        did: 'did:fallback',
        contactCard: _card('did:fallback'),
      ),
    );
    registerFallbackValue(
      cp.GroupAddMemberCommand(
        mnemonic: '',
        groupId: '',
        memberDid: '',
        acceptOfferDid: '',
        offerLink: '',
      ),
    );
  });

  group('concurrent approve + invitation-accept both persist '
      '(regression: lost-update race, real Drift repo)', () {
    late drift_db.GroupsDatabase database;
    late GroupsRepositoryDrift groupsRepo;

    // Stubs for non-persistence collaborators.
    late _MockWallet wallet;
    late _MockConnectionManager connectionManager;
    late _MockConnectionOfferRepository connectionOfferRepository;
    late _MockChannelService channelService;
    late _MockIdentityService identityService;
    late _MockMeetingPlaceControlPlaneSDK controlPlaneSDK;
    late _MockMediatorSDK mediatorSDK;
    late _MockMeetingPlaceTransport channelTransport;
    late _MockDidResolver didResolver;
    late _MockMediatorService mediatorService;

    // DIDs / constants
    const offerLink = 'offer://race-test';
    const groupId = 'group-race-1';
    const groupDid = 'did:test:group-race';
    const ownerDid = 'did:test:alice-race';
    const mediatorDid = 'did:test:mediator-race';
    const publishOfferDid = 'did:test:publish-race';
    const acceptOfferDid = 'did:test:accept-race';

    // Bob = member X that the admin will approve.
    const bobDid = 'did:test:bob-race';
    // Carol = member Y that the handler will add as pendingApproval.
    const carolDid = 'did:test:carol-race';

    setUp(() async {
      database = _inMemoryGroupsDatabase();
      groupsRepo = GroupsRepositoryDrift(database: database);

      // ── Seed the group ──────────────────────────────────────────────────
      // Owner Alice (admin/approved) + Bob (pendingApproval).
      // Carol does not exist yet — the handler will add her.
      final seedGroup = Group(
        id: groupId,
        did: groupDid,
        offerLink: offerLink,
        ownerDid: ownerDid,
        created: DateTime.utc(2026, 1, 1),
        members: [
          GroupMember.admin(did: ownerDid, contactCard: _card(ownerDid)),
          GroupMember(
            did: bobDid,
            dateAdded: DateTime.utc(2026, 1, 2),
            status: GroupMemberStatus.pendingApproval,
            membershipType: GroupMembershipType.member,
            contactCard: _card(bobDid),
          ),
        ],
      );
      await groupsRepo.createGroup(seedGroup);

      // ── Build non-persistence stubs ─────────────────────────────────────
      wallet = _MockWallet();
      connectionManager = _MockConnectionManager();
      connectionOfferRepository = _MockConnectionOfferRepository();
      channelService = _MockChannelService();
      identityService = _MockIdentityService();
      controlPlaneSDK = _MockMeetingPlaceControlPlaneSDK();
      mediatorSDK = _MockMediatorSDK();
      channelTransport = _MockMeetingPlaceTransport();
      didResolver = _MockDidResolver();
      mediatorService = _MockMediatorService();

      final ownerDidMgr = _StubDidManager(ownerDid);
      final publishDidMgr = _StubDidManager(publishOfferDid);

      // ConnectionOffer looked up by both service and handler.
      final connectionOffer = ConnectionOffer(
        offerName: 'Race Group',
        offerLink: offerLink,
        mnemonic: 'test-mnemonic',
        oobInvitationMessage: '',
        status: ConnectionOfferStatus.accepted,
        publishOfferDid: publishOfferDid,
        acceptOfferDid: acceptOfferDid,
        mediatorDid: mediatorDid,
        type: ConnectionOfferType.meetingPlaceInvitation,
        contactCard: _card(ownerDid),
        ownedByMe: true,
        createdAt: DateTime.utc(2026, 1, 1),
        transport: ChannelTransport.matrix,
      );
      when(
        () =>
            connectionOfferRepository.findConnectionOfferByOfferLink(offerLink),
      ).thenAnswer((_) async => connectionOffer);

      // DID resolution for Bob (approve path needs member's DidDocument).
      when(
        () => didResolver.resolveDid(bobDid),
      ).thenAnswer((_) async => DidDocument.create(id: bobDid));

      // getDidManagerForDid for owner (used in _allowMemberToMessageGroupAdmin
      // and identityService.getPermanentIdentity look-up path).
      when(
        () => connectionManager.getDidManagerForDid(any(), ownerDid),
      ).thenAnswer((_) async => ownerDidMgr);

      // getDidManagerForDid for publishOfferDid
      // (approve: senderDid; handler: publishedOfferDidManager).
      when(
        () => connectionManager.getDidManagerForDid(any(), publishOfferDid),
      ).thenAnswer((_) async => publishDidMgr);

      // mediatorSDK.updateAcl: allow-list operation — no-op.
      when(
        () => mediatorSDK.updateAcl(
          ownerDidManager: any(named: 'ownerDidManager'),
          acl: any(named: 'acl'),
          mediatorDid: any(named: 'mediatorDid'),
        ),
      ).thenAnswer((_) async {});

      // identityService.getPermanentIdentity for owner.
      when(
        () => identityService.getPermanentIdentity(any(), ownerDid),
      ).thenAnswer(
        (_) async => PermanentIdentity(
          didManager: ownerDidMgr,
          didDocument: DidDocument.create(id: ownerDid),
        ),
      );

      // Group channel (approve path inviteToChannel + handler findChannel).
      final groupChannel = Channel(
        offerLink: offerLink,
        publishOfferDid: publishOfferDid,
        mediatorDid: mediatorDid,
        status: ChannelStatus.inaugurated,
        isConnectionInitiator: true,
        contactCard: _card(ownerDid),
        type: ChannelType.group,
        permanentChannelDid: ownerDid,
        otherPartyPermanentChannelDid: groupDid,
      );
      when(
        () =>
            channelService.getChannelByOtherPartyPermanentChannelDid(groupDid),
      ).thenAnswer((_) async => groupChannel);

      when(
        () => channelTransport.inviteToChannel(
          channel: any(named: 'channel'),
          participantDid: any(named: 'participantDid'),
          didManager: any(named: 'didManager'),
        ),
      ).thenAnswer((_) async {});

      // mediatorSDK.sendMessage: inauguration message — no-op.
      when(() => mediatorSDK.sendMessage(any())).thenAnswer((_) async {});

      // controlPlaneSDK.execute: GroupAddMemberCommand — no-op.
      when(
        () => controlPlaneSDK.execute<cp.GroupAddMemberCommandOutput>(any()),
      ).thenAnswer((_) async => _FakeGroupAddMemberCommandOutput());

      // ── Handler mediator stub ────────────────────────────────────────────
      // Carol's InvitationAcceptanceGroup message, as fetched from mediator.
      final carolAcceptanceMsg = _buildAcceptanceMessage(
        from: acceptOfferDid,
        to: publishOfferDid,
        channelDid: carolDid,
        contactCard: _card(carolDid),
      );
      when(
        () => mediatorService.fetchMessages(
          didManager: any(named: 'didManager'),
          mediatorDid: mediatorDid,
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => [
          MediatorMessage(
            plainTextMessage: carolAcceptanceMsg,
            messageHash: 'hash-carol',
          ),
        ],
      );
      when(
        () => mediatorService.deleteMessages(
          didManager: any(named: 'didManager'),
          mediatorDid: mediatorDid,
          messageHashes: any(named: 'messageHashes'),
        ),
      ).thenAnswer((_) async {});

      // channelService.persistChannel: no-op (handler saves Carol's channel).
      when(() => channelService.persistChannel(any())).thenAnswer((_) async {});
    });

    tearDown(() => database.close());

    test('both Bob (approved) and Carol (pendingApproval) survive '
        'after concurrent execution', () async {
      // ── Construct the REAL production objects ──────────────────────────
      //   GroupsRepositoryDrift is the single shared persistence layer
      //   injected into both.  Everything else is stubbed.

      final groupService = GroupService(
        wallet: wallet,
        connectionManager: connectionManager,
        connectionOfferRepository: connectionOfferRepository,
        groupRepository: groupsRepo, // REAL drift repo
        channelService: channelService,
        offerService: _MockConnectionOfferService(),
        connectionService: _MockConnectionService(),
        identityService: identityService,
        controlPlaneSDK: controlPlaneSDK,
        mediatorSDK: mediatorSDK,
        channelTransport: channelTransport,
        didResolver: didResolver,
      );

      final handler = InvitationGroupAcceptedEventHandler(
        wallet: wallet,
        connectionOfferRepository: connectionOfferRepository,
        channelService: channelService,
        connectionManager: connectionManager,
        mediatorService: mediatorService,
        groupRepository: groupsRepo, // SAME REAL drift repo
        options: const ControlPlaneEventHandlerManagerOptions(),
        logger: DefaultMeetingPlaceCoreSDKLogger(),
      );

      // Channel representing Bob's waiting-for-approval state.
      final bobChannel = Channel(
        offerLink: offerLink,
        publishOfferDid: publishOfferDid,
        acceptOfferDid: acceptOfferDid,
        mediatorDid: mediatorDid,
        status: ChannelStatus.waitingForApproval,
        contactCard: _card(ownerDid),
        otherPartyContactCard: _card(bobDid),
        type: ChannelType.group,
        isConnectionInitiator: true,
        permanentChannelDid: ownerDid,
        otherPartyPermanentChannelDid: bobDid,
      );

      // InvitationGroupAccept event that triggers Carol's insertion.
      final carolEvent = cp.InvitationGroupAccept(
        id: const Uuid().v4(),
        acceptOfferAsDid: acceptOfferDid,
        offerLink: offerLink,
      );

      // ── Concurrent execution ───────────────────────────────────────────
      // Both coroutines start before either yields; they genuinely
      // interleave at every await point. SQLite serialises the actual DB
      // writes so neither can lose data.
      await Future.wait([
        groupService.approveMembershipRequest(channel: bobChannel),
        handler.process(carolEvent),
      ]);

      // ── Re-read from the REAL drift repository ─────────────────────────
      final finalGroup = await groupsRepo.findGroupByOfferLink(offerLink);
      expect(
        finalGroup,
        isNotNull,
        reason: 'group must still exist after concurrent writes',
      );

      final members = finalGroup!.members;

      // Total: owner Alice + Bob + Carol = 3.
      expect(
        members.length,
        equals(3),
        reason: 'no member must be silently dropped by a full-list replace',
      );

      // Bob must be approved (the approve path ran atomically).
      final bob = members.firstWhere(
        (m) => m.did == bobDid,
        orElse: () =>
            throw TestFailure('Bob is missing — lost-update regression!'),
      );
      expect(
        bob.status,
        equals(GroupMemberStatus.approved),
        reason: 'approveMembershipRequest must have updated Bob to approved',
      );

      // Carol must be present as pendingApproval (the handler ran
      // atomically).
      final carol = members.firstWhere(
        (m) => m.did == carolDid,
        orElse: () =>
            throw TestFailure('Carol is missing — lost-update regression!'),
      );
      expect(
        carol.status,
        equals(GroupMemberStatus.pendingApproval),
        reason:
            'InvitationGroupAcceptedEventHandler must have added Carol '
            'as pendingApproval',
      );
    });
  });
}
