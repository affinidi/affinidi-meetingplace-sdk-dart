import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/src/chat/group/group_matrix_chat_sdk.dart';
import 'package:meeting_place_matrix/src/chat/group/listener/pending_approvals_listener.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

class _MockLogger extends Mock implements MeetingPlaceChatSDKLogger {}

/// Minimal hand-rolled stub that gives [PendingApprovalsListener] exactly what
/// it needs from [GroupMatrixChatSDK] without pulling in the full Matrix stack.
///
/// [group] is a real mutable field so the listener's `_chatSDK.group =` write
/// works naturally without any setter-stub gymnastics.
class _StubGroupSDK implements GroupMatrixChatSDK {
  _StubGroupSDK({
    required this.coreSDK,
    required this.chatRepository,
    required this.logger,
    required Group initialGroup,
    required this.chatStream,
  }) : group = initialGroup;

  @override
  final MeetingPlaceCoreSDK coreSDK;

  @override
  final ChatRepository chatRepository;

  @override
  final MeetingPlaceChatSDKLogger logger;

  @override
  Group group;

  @override
  final ChatStream chatStream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ContactCard _card(String did) =>
    ContactCard(did: did, type: 'human', contactInfo: {'n': did});

Group _groupWithPendingMember({
  required String groupDid,
  required String memberDid,
}) => Group(
  id: 'group-1',
  did: groupDid,
  offerLink: 'offer://test',
  created: DateTime.utc(2026, 1, 1),
  ownerDid: 'did:test:alice',
  publicKey: 'pk',
  status: GroupStatus.created,
  members: [
    GroupMember.admin(
      did: 'did:test:alice',
      publicKey: 'pk-alice',
      contactCard: _card('did:test:alice'),
    ),
    GroupMember(
      did: memberDid,
      publicKey: 'pk-member',
      dateAdded: DateTime.utc(2026, 1, 2),
      status: GroupMemberStatus.pendingApproval,
      membershipType: GroupMembershipType.member,
      contactCard: _card(memberDid),
    ),
  ],
);

ControlPlaneStreamEvent _acceptEvent(String groupDid) =>
    ControlPlaneStreamEvent(
      type: ControlPlaneEventType.InvitationGroupAccept,
      channel: Channel(
        offerLink: 'offer://test',
        publishOfferDid: 'did:test:pub',
        mediatorDid: 'did:test:med',
        status: ChannelStatus.inaugurated,
        contactCard: _card('did:test:member'),
        type: ChannelType.group,
        transport: ChannelTransport.matrix,
        isConnectionInitiator: false,
        otherPartyPermanentChannelDid: groupDid,
      ),
    );

ConciergeMessage _stubConcierge() => ConciergeMessage(
  chatId: 'c',
  messageId: 'm',
  senderDid: 's',
  isFromMe: false,
  dateCreated: DateTime.utc(2026),
  status: ChatItemStatus.queued,
  data: const {},
  conciergeType: ConciergeMessageType.permissionToJoinGroup,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const groupDid = 'did:test:group';
  const memberDid = 'did:test:bob';

  late StreamController<ControlPlaneStreamEvent> streamController;
  late _MockCoreSDK coreSDK;
  late _MockChatRepository chatRepository;
  late _MockLogger logger;
  late ChatStream chatStream;
  late Group grp;

  setUpAll(() {
    registerFallbackValue(_stubConcierge());
  });

  setUp(() {
    streamController = StreamController<ControlPlaneStreamEvent>.broadcast();
    coreSDK = _MockCoreSDK();
    chatRepository = _MockChatRepository();
    logger = _MockLogger();
    chatStream = ChatStream();
    grp = _groupWithPendingMember(groupDid: groupDid, memberDid: memberDid);

    when(
      () => coreSDK.controlPlaneEventsStream,
    ).thenAnswer((_) => streamController.stream);
    when(() => coreSDK.getGroupById('group-1')).thenAnswer((_) async => grp);
    when(
      () => chatRepository.createMessage(any()),
    ).thenAnswer((_) async => _stubConcierge());
    when(() => logger.info(any(), name: any(named: 'name'))).thenReturn(null);
  });

  tearDown(() async {
    await streamController.close();
  });

  _StubGroupSDK buildStub({ChatStream? stream}) => _StubGroupSDK(
    coreSDK: coreSDK,
    chatRepository: chatRepository,
    logger: logger,
    initialGroup: grp,
    chatStream: stream ?? chatStream,
  );

  // -------------------------------------------------------------------------
  // (a) Single-subscription invariant (Fix A)
  //
  // Two PendingApprovalsListener subscriptions stacked on the same stream —
  // one per un-cancelled startChatSession() call — each bound to their own
  // empty Chat object both pass the in-memory dedup check independently →
  // two concierge cards (the intermittent bug).
  //
  // Fix A: await _controlPlaneSubscription?.cancel() before re-arming ensures
  // only one listener is live at any time → one card per event.
  // -------------------------------------------------------------------------

  group('startChatSession called twice: subscription behaviour', () {
    test(
      'two stacked subscriptions produce two concierges (pre-fix repro)',
      () async {
        // Two distinct Chat objects — each starts with no messages,
        // mirroring the separate Chat instances two startChatSession()
        // calls would return.
        final chat1 = Chat(id: 'chat-1', stream: ChatStream(), messages: []);
        final chat2 = Chat(id: 'chat-1', stream: ChatStream(), messages: []);

        // Bug: no cancellation between first and second startChatSession.
        // Each listener has its own chat object; both pass the dedup check.
        final sub1 = PendingApprovalsListener(buildStub()).listen(chat1);
        final sub2 = PendingApprovalsListener(buildStub()).listen(chat2);

        streamController.add(_acceptEvent(groupDid));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Both callbacks fire independently → two createMessage calls.
        verify(() => chatRepository.createMessage(any())).called(2);

        await sub1.cancel();
        await sub2.cancel();
      },
    );

    test(
      'cancelling first subscription before second (Fix A): one concierge',
      () async {
        final stub = buildStub();
        final chat = Chat(id: 'chat-1', stream: chatStream, messages: []);

        final sub1 = PendingApprovalsListener(stub).listen(chat);
        // Fix A: await cancel before reassigning _controlPlaneSubscription.
        await sub1.cancel();
        final sub2 = PendingApprovalsListener(stub).listen(chat);

        streamController.add(_acceptEvent(groupDid));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Only the live subscription fires: exactly one concierge.
        verify(() => chatRepository.createMessage(any())).called(1);

        await sub2.cancel();
      },
    );
  });

  // -------------------------------------------------------------------------
  // (b) Concurrent InvitationGroupAccept events serialised by mutex (Fix B)
  //
  // Two near-simultaneous events for the same member: without the mutex both
  // async callbacks can pass the _hasConciergeMessage check before either
  // completes chat.messages.add → two cards.  The _mutex in
  // PendingApprovalsListener serialises the protected block so the second
  // callback sees the concierge already in chat.messages → one card.
  // -------------------------------------------------------------------------

  group('concurrent InvitationGroupAccept events for the same member', () {
    test('produce exactly one concierge card (mutex serialisation)', () async {
      // Delay in createMessage creates the interleaving window that would
      // produce a duplicate without the mutex.
      when(() => chatRepository.createMessage(any())).thenAnswer(
        (_) => Future<ChatItem>.delayed(
          const Duration(milliseconds: 10),
          _stubConcierge,
        ),
      );

      final stub = buildStub();
      final chat = Chat(id: 'chat-1', stream: chatStream, messages: []);
      final sub = PendingApprovalsListener(stub).listen(chat);

      // Add both events without awaiting; both land in the stream queue and
      // the listener begins processing them concurrently.
      streamController.add(_acceptEvent(groupDid));
      streamController.add(_acceptEvent(groupDid));

      // Wait long enough for both mutex-serialised callbacks to finish.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // With Fix B: the second callback waits for the first to complete
      // (chat.messages.add already done) → it skips → one createMessage call.
      verify(() => chatRepository.createMessage(any())).called(1);

      await sub.cancel();
    });
  });
}
