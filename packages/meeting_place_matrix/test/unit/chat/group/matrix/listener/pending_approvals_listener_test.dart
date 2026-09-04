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
/// The `_chatSDK.group =` write is the terminal step of every
/// mutex-protected callback (both the create and the dedup-skip path), so
/// [onGroupUpdated] gives tests a deterministic "callback finished" signal
/// to await instead of a fixed wall-clock delay.
class _StubGroupSDK implements GroupMatrixChatSDK {
  _StubGroupSDK({
    required this.coreSDK,
    required this.chatRepository,
    required this.logger,
    required Group initialGroup,
    required this.chatStream,
    this.onGroupUpdated,
  }) : _group = initialGroup;

  @override
  final MeetingPlaceCoreSDK coreSDK;

  @override
  final ChatRepository chatRepository;

  @override
  final MeetingPlaceChatSDKLogger logger;

  @override
  final ChatStream chatStream;

  final void Function()? onGroupUpdated;

  Group _group;

  @override
  Group get group => _group;

  @override
  set group(Group value) {
    _group = value;
    onGroupUpdated?.call();
  }

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
  status: GroupStatus.created,
  members: [
    GroupMember.admin(
      did: 'did:test:alice',
      contactCard: _card('did:test:alice'),
    ),
    GroupMember(
      did: memberDid,
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
    when(() => coreSDK.findGroupById('group-1')).thenAnswer((_) async => grp);
    when(
      () => chatRepository.createMessage(any()),
    ).thenAnswer((_) async => _stubConcierge());
    when(() => logger.info(any(), name: any(named: 'name'))).thenReturn(null);
  });

  tearDown(() async {
    await streamController.close();
  });

  _StubGroupSDK buildStub({
    ChatStream? stream,
    void Function()? onGroupUpdated,
  }) => _StubGroupSDK(
    coreSDK: coreSDK,
    chatRepository: chatRepository,
    logger: logger,
    initialGroup: grp,
    chatStream: stream ?? chatStream,
    onGroupUpdated: onGroupUpdated,
  );

  // -------------------------------------------------------------------------
  // (a) Stacked-subscription bug at the listener level
  //
  // Demonstrates what happens when two PendingApprovalsListener subscriptions
  // are live simultaneously on the same control-plane stream — each bound to
  // its own Chat object so both pass the in-memory dedup check independently.
  // This is the underlying bug that Fix A (cancel before re-arm in
  // startChatSession) prevents.
  //
  // For a test that guards Fix A by driving the REAL startChatSession() code
  // path, see group_matrix_chat_sdk_start_session_test.dart.
  // -------------------------------------------------------------------------

  group(
    'PendingApprovalsListener: stacked subscriptions produce duplicates',
    () {
      test(
        'two live listeners on the same stream each fire independently',
        () async {
          // Two distinct Chat objects — each starts with no messages,
          // mirroring the separate Chat instances two un-cancelled
          // startChatSession() calls would return.
          final chat1 = Chat(id: 'chat-1', stream: ChatStream(), messages: []);
          final chat2 = Chat(id: 'chat-1', stream: ChatStream(), messages: []);

          // Both callbacks write back the refreshed group as their terminal
          // step; waiting for both writes is a deterministic completion
          // signal instead of a fixed wall-clock delay.
          var groupUpdates = 0;
          final bothProcessed = Completer<void>();
          void onGroupUpdated() {
            groupUpdates++;
            if (groupUpdates == 2) bothProcessed.complete();
          }

          // Both listeners armed with no cancellation between them, mirroring
          // the pre-fix startChatSession() re-entry bug.
          final sub1 = PendingApprovalsListener(
            buildStub(onGroupUpdated: onGroupUpdated),
          ).listen(chat1);
          final sub2 = PendingApprovalsListener(
            buildStub(onGroupUpdated: onGroupUpdated),
          ).listen(chat2);

          streamController.add(_acceptEvent(groupDid));
          await bothProcessed.future.timeout(const Duration(seconds: 5));

          // Both callbacks fire independently → two createMessage calls.
          verify(() => chatRepository.createMessage(any())).called(2);

          await sub1.cancel();
          await sub2.cancel();
        },
      );
    },
  );

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

      // The group write-back is the terminal step of each mutex-protected
      // callback; waiting for both gives a deterministic completion signal
      // instead of guessing a wall-clock delay long enough for both.
      var groupUpdates = 0;
      final bothProcessed = Completer<void>();
      void onGroupUpdated() {
        groupUpdates++;
        if (groupUpdates == 2) bothProcessed.complete();
      }

      final stub = buildStub(onGroupUpdated: onGroupUpdated);
      final chat = Chat(id: 'chat-1', stream: chatStream, messages: []);
      final sub = PendingApprovalsListener(stub).listen(chat);

      // Add both events without awaiting; both land in the stream queue and
      // the listener begins processing them concurrently.
      streamController.add(_acceptEvent(groupDid));
      streamController.add(_acceptEvent(groupDid));

      await bothProcessed.future.timeout(const Duration(seconds: 5));

      // With Fix B: the second callback waits for the first to complete
      // (chat.messages.add already done) → it skips → one createMessage call.
      verify(() => chatRepository.createMessage(any())).called(1);

      await sub.cancel();
    });
  });
}
