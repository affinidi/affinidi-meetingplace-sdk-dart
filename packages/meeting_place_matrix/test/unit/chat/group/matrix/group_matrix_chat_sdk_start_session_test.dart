// Tests for GroupMatrixChatSDK.startChatSession — covers two independent
// fixes.

import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/src/chat/group/group_matrix_chat_sdk.dart';
import 'package:meeting_place_matrix/src/matrix_room_subscription.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../fakes/fake_fallbacks.dart';

// ---------------------------------------------------------------------------
// Mocks / fakes
// ---------------------------------------------------------------------------

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

/// Minimal IncomingMessageHandle whose stream never emits — keeps the
/// background bootstrap suspended so it does not make additional SDK calls
/// during the test.
class _SilentHandle implements IncomingMessageHandle {
  final _controller = StreamController<IncomingMessage>.broadcast();

  @override
  Stream<IncomingMessage> get stream => _controller.stream;

  @override
  Future<void> dispose() => _controller.close();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ContactCard _card(String did) =>
    ContactCard(did: did, type: 'human', contactInfo: {'n': did});

/// Group owned by alice with no pending members — the initial startChatSession
/// call will therefore not create any concierge messages, keeping
/// chatRepository.createMessage calls exclusively from the listener path.
Group _groupNoMembers() => Group(
  id: 'group-1',
  did: 'did:test:group',
  offerLink: 'offer://test',
  created: DateTime.utc(2026, 1, 1),
  ownerDid: 'did:test:alice',
  status: GroupStatus.created,
  members: [
    GroupMember.admin(
      did: 'did:test:alice',
      contactCard: _card('did:test:alice'),
    ),
  ],
);

/// Group returned by findGroupById after an InvitationGroupAccept event —
/// contains one pending member so PendingApprovalConciergeFactory creates a
/// concierge and calls chatRepository.createMessage.
Group _groupWithPendingMember() => Group(
  id: 'group-1',
  did: 'did:test:group',
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
      did: 'did:test:bob',
      dateAdded: DateTime.utc(2026, 1, 2),
      status: GroupMemberStatus.pendingApproval,
      membershipType: GroupMembershipType.member,
      contactCard: _card('did:test:bob'),
    ),
  ],
);

ConciergeMessage _stubConcierge() => ConciergeMessage(
  chatId: 'c',
  messageId: 'm',
  senderDid: 'did:test:bob',
  isFromMe: false,
  dateCreated: DateTime.utc(2026),
  status: ChatItemStatus.userInput,
  data: {'memberDid': 'did:test:bob'},
  conciergeType: ConciergeMessageType.permissionToJoinGroup,
);

ControlPlaneStreamEvent _acceptEvent() => ControlPlaneStreamEvent(
  type: ControlPlaneEventType.invitationGroupAccept,
  channel: Channel(
    offerLink: 'offer://test',
    publishOfferDid: 'did:test:pub',
    mediatorDid: 'did:test:med',
    status: ChannelStatus.inaugurated,
    contactCard: _card('did:test:bob'),
    type: ChannelType.group,
    transport: ChannelTransport.matrix,
    isConnectionInitiator: false,
    otherPartyPermanentChannelDid: 'did:test:group',
  ),
);

GroupMatrixChatSDK _buildSdk({
  required _MockCoreSDK coreSDK,
  required _MockChatRepository chatRepository,
  ContactCard? card,
}) => GroupMatrixChatSDK(
  coreSDK: coreSDK,
  did: 'did:test:alice', // matches group.ownerDid → isGroupOwner = true
  otherPartyDid: 'did:test:group',
  mediatorDid: 'did:test:med',
  chatRepository: chatRepository,
  options: MeetingPlaceChatSDKOptions(
    chatPresenceSendInterval: const Duration(hours: 1),
  ),
  group: _groupNoMembers(),
  card: card,
);

/// Channel returned by coreSDK.findChannelByOtherPartyPermanentDid, holding
/// the contact card as last stored on the channel (used by
/// ProposeProfileUpdateAction to detect a stale card).
Channel _channel(ContactCard card) => Channel(
  offerLink: 'offer://test',
  publishOfferDid: 'did:test:pub',
  mediatorDid: 'did:test:med',
  status: ChannelStatus.inaugurated,
  contactCard: card,
  type: ChannelType.group,
  transport: ChannelTransport.matrix,
  isConnectionInitiator: false,
  otherPartyPermanentChannelDid: 'did:test:group',
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MatrixRoomSubscription(
        ownerDid: '',
        options: TransportSubscriptionOptions(excludeSelf: true),
      ),
    );
    registerFallbackValue(_stubConcierge());
    registerFallbackValue(FakeChannel());
  });

  group(
    'GroupMatrixChatSDK.startChatSession — control-plane subscription re-arm',
    () {
      late _MockCoreSDK coreSDK;
      late _MockChatRepository chatRepository;
      late StreamController<ControlPlaneStreamEvent> controlPlaneController;
      late Completer<IncomingMessageHandle> subscribeCompleter;
      late _SilentHandle handle;

      setUp(() {
        coreSDK = _MockCoreSDK();
        chatRepository = _MockChatRepository();
        controlPlaneController =
            StreamController<ControlPlaneStreamEvent>.broadcast();
        subscribeCompleter = Completer<IncomingMessageHandle>();
        handle = _SilentHandle();

        // Matrix room subscribe stays pending — keeps background bootstrap
        // suspended so no additional SDK calls happen during the test.
        when(
          () => coreSDK.subscribe(any()),
        ).thenAnswer((_) => subscribeCompleter.future);

        when(
          () => coreSDK.controlPlaneEventsStream,
        ).thenAnswer((_) => controlPlaneController.stream);

        // findGroupById returns a group with one pending member so the listener
        // has something to create a concierge for.
        when(
          () => coreSDK.findGroupById('group-1'),
        ).thenAnswer((_) async => _groupWithPendingMember());

        when(
          () => chatRepository.listMessages(any()),
        ).thenAnswer((_) async => []);

        when(
          () => chatRepository.getSyncMarker(any()),
        ).thenAnswer((_) async => null);

        when(
          () => chatRepository.createMessage(any()),
        ).thenAnswer((_) async => _stubConcierge());
      });

      tearDown(() async {
        subscribeCompleter.complete(handle);
        await handle.dispose();
        await controlPlaneController.close();
      });

      test('cancels previous subscription before re-arming: '
          'one concierge per event', () async {
        final sdk = _buildSdk(coreSDK: coreSDK, chatRepository: chatRepository);

        // First session start → first control-plane subscription armed.
        await sdk.startChatSession();
        // Second session start → Fix A cancels the first subscription before
        // arming the second.  Without the cancel line both subscriptions are
        // live and the event below triggers createMessage twice.
        await sdk.startChatSession();

        // One InvitationGroupAccept event arrives.
        controlPlaneController.add(_acceptEvent());

        // Wait for the listener's createMessage call, then flush the event
        // queue so a second, unserialised call from a stale un-cancelled
        // subscription — were Fix A missing — would also complete before
        // the assertion below runs. Deterministic: no wall-clock guess.
        await untilCalled(() => chatRepository.createMessage(any()));
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }

        // Exactly one live subscription → exactly one createMessage call.
        // Remove `await _controlPlaneSubscription?.cancel();` from
        // startChatSession() and this expectation becomes called(2).
        verify(() => chatRepository.createMessage(any())).called(1);
      });
    },
  );

  group(
    'GroupMatrixChatSDK.startChatSession — automatic profile-update proposal',
    () {
      late _MockCoreSDK coreSDK;
      late _MockChatRepository chatRepository;
      late StreamController<ControlPlaneStreamEvent> controlPlaneController;
      late Completer<IncomingMessageHandle> subscribeCompleter;
      late _SilentHandle handle;

      setUp(() {
        coreSDK = _MockCoreSDK();
        chatRepository = _MockChatRepository();
        controlPlaneController =
            StreamController<ControlPlaneStreamEvent>.broadcast();
        subscribeCompleter = Completer<IncomingMessageHandle>();
        handle = _SilentHandle();

        when(
          () => coreSDK.subscribe(any()),
        ).thenAnswer((_) => subscribeCompleter.future);

        when(
          () => coreSDK.controlPlaneEventsStream,
        ).thenAnswer((_) => controlPlaneController.stream);

        when(
          () => chatRepository.listMessages(any()),
        ).thenAnswer((_) async => []);

        when(
          () => chatRepository.getSyncMarker(any()),
        ).thenAnswer((_) async => null);

        when(
          () => chatRepository.createMessage(any()),
        ).thenAnswer((inv) async => inv.positionalArguments.first as ChatItem);

        // The channel's last-stored card differs from the SDK's current
        // card, so ProposeProfileUpdateAction should propose an update.
        when(
          () => coreSDK.findChannelByOtherPartyPermanentDid('did:test:group'),
        ).thenAnswer((_) async => _channel(_card('did:test:group-stale')));

        when(() => coreSDK.updateChannel(any())).thenAnswer((_) async {});
      });

      tearDown(() async {
        subscribeCompleter.complete(handle);
        await handle.dispose();
        await controlPlaneController.close();
      });

      test('proposes a profile update when the current card differs from the '
          'stored channel card', () async {
        final sdk = _buildSdk(
          coreSDK: coreSDK,
          chatRepository: chatRepository,
          card: _card('did:test:alice-fresh'),
        );

        await sdk.startChatSession();

        // proposeProfileUpdate() runs unawaited from onChatSessionStarted();
        // wait for it to complete rather than guessing at wall-clock delay.
        // Bounded so a regression (no createMessage call) fails fast instead
        // of hanging for the suite's full 120s timeout.
        await untilCalled(
          () => chatRepository.createMessage(any()),
        ).timeout(const Duration(seconds: 2));

        verify(() => chatRepository.createMessage(any())).called(1);
      });
    },
  );
}
