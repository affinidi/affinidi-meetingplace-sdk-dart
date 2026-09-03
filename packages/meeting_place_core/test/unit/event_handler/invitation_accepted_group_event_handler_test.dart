import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    as cp;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/event_handler/invitation_accepted_group_event_handler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'mocks/mocks.dart';

// ---------------------------------------------------------------------------
// Additional mocks not in the shared mocks.dart
// ---------------------------------------------------------------------------

class _MockGroupRepository extends Mock implements GroupRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ContactCard _contactCard(String did) => ContactCard(
  did: did,
  type: 'individual',
  contactInfo: const {'fullName': 'Test User'},
);

/// Builds a PlainTextMessage that InvitationGroupAcceptedEventHandler decodes
/// as an InvitationAcceptanceGroup (the message sent by the joiner to admin).
PlainTextMessage _acceptanceMessage({
  required String from,
  required String to,
  required String channelDid,
  ContactCard? contactCard,
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

Group _makeGroup({
  required String ownerDid,
  required String groupDid,
  required String offerLink,
  List<GroupMember> extraMembers = const [],
}) {
  return Group(
    id: 'group-1',
    did: groupDid,
    offerLink: offerLink,
    created: DateTime.utc(2026, 1, 1),
    ownerDid: ownerDid,
    members: [
      GroupMember.admin(did: ownerDid, contactCard: _contactCard(ownerDid)),
      ...extraMembers,
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late InvitationGroupAcceptedEventHandler handler;
  late MockWallet mockWallet;
  late MockConnectionOfferRepository mockConnectionOfferRepository;
  late MockChannelService mockChannelService;
  late MockConnectionManager mockConnectionManager;
  late MockMediatorService mockMediatorService;
  late MockDidManager mockPublishOfferDidManager;
  late _MockGroupRepository mockGroupRepository;

  const offerLink = 'offer://group-test';
  const publishOfferDid = 'did:test:publisher';
  const groupDid = 'did:test:group';
  const adminDid = 'did:test:admin';
  const joinerDid = 'did:test:joiner-permanent';
  const mediatorDid = 'did:web:mediator';
  const acceptOfferDid = 'did:test:accept-offer';
  const messageHash = 'hash-abc';

  setUpAll(() {
    registerFallbackValue(FakeChannel());
    registerFallbackValue(FakeDidManager());
    registerFallbackValue(FakeGroup());
    registerFallbackValue(FakeFetchMessagesOptions());
    // addMemberIfAbsent takes a GroupMember; any() requires a
    // registered fallback.
    registerFallbackValue(
      GroupMember.pendingMember(
        did: 'did:fallback',
        contactCard: ContactCard(
          did: 'did:fallback',
          type: 'individual',
          contactInfo: const {},
        ),
      ),
    );
  });

  setUp(() {
    mockWallet = MockWallet();
    mockConnectionOfferRepository = MockConnectionOfferRepository();
    mockChannelService = MockChannelService();
    mockConnectionManager = MockConnectionManager();
    mockMediatorService = MockMediatorService();
    mockPublishOfferDidManager = MockDidManager(did: publishOfferDid);
    mockGroupRepository = _MockGroupRepository();

    handler = InvitationGroupAcceptedEventHandler(
      wallet: mockWallet,
      connectionOfferRepository: mockConnectionOfferRepository,
      channelService: mockChannelService,
      connectionManager: mockConnectionManager,
      mediatorService: mockMediatorService,
      groupRepository: mockGroupRepository,
      options: const ControlPlaneEventHandlerManagerOptions(),
      logger: DefaultMeetingPlaceCoreSDKLogger(),
    );

    // Default: delete mediator messages succeeds
    when(
      () => mockMediatorService.deleteMessages(
        didManager: any(named: 'didManager'),
        mediatorDid: any(named: 'mediatorDid'),
        messageHashes: any(named: 'messageHashes'),
      ),
    ).thenAnswer((_) async {});

    // ConnectionOffer lookup
    when(
      () => mockConnectionOfferRepository.getConnectionOfferByOfferLink(
        offerLink,
      ),
    ).thenAnswer(
      (_) async => ConnectionOffer(
        offerName: 'Group Offer',
        offerLink: offerLink,
        mnemonic: 'test-mnemonic',
        oobInvitationMessage: '',
        status: ConnectionOfferStatus.published,
        publishOfferDid: publishOfferDid,
        mediatorDid: mediatorDid,
        type: ConnectionOfferType.meetingPlaceInvitation,
        contactCard: _contactCard(adminDid),
        ownedByMe: true,
        createdAt: DateTime.utc(2026, 1, 1),
        transport: ChannelTransport.matrix,
      ),
    );

    // DID manager for the publish-offer DID
    when(
      () => mockConnectionManager.getDidManagerForDid(
        mockWallet,
        publishOfferDid,
      ),
    ).thenAnswer((_) async => mockPublishOfferDidManager);

    // findChannelByOtherPartyPermanentChannelDid for the group channel
    when(
      () => mockChannelService.findChannelByOtherPartyPermanentChannelDid(
        groupDid,
      ),
    ).thenAnswer(
      (_) async => Channel(
        offerLink: offerLink,
        publishOfferDid: publishOfferDid,
        mediatorDid: mediatorDid,
        status: ChannelStatus.inaugurated,
        isConnectionInitiator: true,
        contactCard: _contactCard(adminDid),
        type: ChannelType.group,
        permanentChannelDid: adminDid,
        otherPartyPermanentChannelDid: groupDid,
      ),
    );

    // persistChannel succeeds
    when(
      () => mockChannelService.persistChannel(any()),
    ).thenAnswer((_) async {});
  });

  MediatorMessage buildMediatorMessage(PlainTextMessage plainText) {
    return MediatorMessage(
      plainTextMessage: plainText,
      messageHash: messageHash,
    );
  }

  void stubMediatorFetch(List<MediatorMessage> messages) {
    when(
      () => mockMediatorService.fetchMessages(
        didManager: mockPublishOfferDidManager,
        mediatorDid: mediatorDid,
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => messages);
  }

  final event = cp.InvitationGroupAccept(
    id: const Uuid().v4(),
    acceptOfferAsDid: acceptOfferDid,
    offerLink: offerLink,
  );

  group('atomic add-if-absent on InvitationGroupAccept', () {
    test(
      'calls addMemberIfAbsent with the joiner DID even when already '
      'present (idempotent — repository decides whether to insert)',
      () async {
        // Group already has the joiner as pendingApproval (e.g. first
        // InvitationGroupAccept was already processed). The handler must still
        // call addMemberIfAbsent so the repository can enforce the uniqueness
        // check; it must NOT silently skip the call based on in-memory state.
        final groupWithJoiner = _makeGroup(
          ownerDid: adminDid,
          groupDid: groupDid,
          offerLink: offerLink,
          extraMembers: [
            GroupMember.pendingMember(
              did: joinerDid,
              contactCard: _contactCard(joinerDid),
            ),
          ],
        );

        when(
          () => mockGroupRepository.getGroupByOfferLink(offerLink),
        ).thenAnswer((_) async => groupWithJoiner);

        when(
          () => mockGroupRepository.addMemberIfAbsent(any(), any()),
        ).thenAnswer((_) async {});

        final message = _acceptanceMessage(
          from: acceptOfferDid,
          to: publishOfferDid,
          channelDid: joinerDid,
          contactCard: _contactCard(joinerDid),
        );

        stubMediatorFetch([buildMediatorMessage(message)]);

        await handler.process(event);

        // addMemberIfAbsent must be called with the joiner as a pendingApproval
        // member — the repository is the authority on whether the row already
        // exists, not the in-memory snapshot.
        final captured =
            verify(
                  () => mockGroupRepository.addMemberIfAbsent(
                    'group-1',
                    captureAny(),
                  ),
                ).captured.single
                as GroupMember;
        expect(captured.did, joinerDid);
        expect(captured.status, GroupMemberStatus.pendingApproval);
        // updateGroup must never be called from the handler — it would clobber
        // concurrent approve status changes.
        verifyNever(() => mockGroupRepository.updateGroup(any()));
      },
    );

    test('calls addMemberIfAbsent when the joiner DID is new '
        '(control: normal flow is not broken)', () async {
      // Group does NOT yet have the joiner.
      final groupWithoutJoiner = _makeGroup(
        ownerDid: adminDid,
        groupDid: groupDid,
        offerLink: offerLink,
      );

      when(
        () => mockGroupRepository.getGroupByOfferLink(offerLink),
      ).thenAnswer((_) async => groupWithoutJoiner);

      when(
        () => mockGroupRepository.addMemberIfAbsent(any(), any()),
      ).thenAnswer((_) async {});

      final message = _acceptanceMessage(
        from: acceptOfferDid,
        to: publishOfferDid,
        channelDid: joinerDid, // new DID
        contactCard: _contactCard(joinerDid),
      );

      stubMediatorFetch([buildMediatorMessage(message)]);

      await handler.process(event);

      // addMemberIfAbsent must be called exactly once with the new joiner.
      final captured =
          verify(
                () => mockGroupRepository.addMemberIfAbsent(
                  'group-1',
                  captureAny(),
                ),
              ).captured.single
              as GroupMember;
      expect(captured.did, joinerDid);
      expect(captured.status, GroupMemberStatus.pendingApproval);
      verifyNever(() => mockGroupRepository.updateGroup(any()));
    });
  });
}
