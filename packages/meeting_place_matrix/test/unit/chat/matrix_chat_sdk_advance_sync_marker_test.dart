import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/src/chat/individual/individual_matrix_chat_sdk.dart';
import 'package:meeting_place_matrix/src/matrix_incoming_message.dart';
import 'package:meeting_place_matrix/src/matrix_room_history_query.dart';
import 'package:meeting_place_matrix/src/matrix_room_subscription.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockVdipClient extends Mock implements VdipClient {}

class _MockVdipSubscription extends Mock
    implements
        CoreSDKStreamSubscription<
          MediatorMessage,
          MediatorStreamProcessingResult
        > {}

class _MockChatRepository extends Mock implements ChatRepository {}

class _FakeOutgoingMessage extends Fake implements OutgoingMessage {}

class _FakeHandle implements IncomingMessageHandle {
  _FakeHandle(this._controller);

  final StreamController<IncomingMessage> _controller;

  @override
  Stream<IncomingMessage> get stream => _controller.stream;

  @override
  Future<void> dispose() async => _controller.close();
}

const _aliceDid = 'did:test:alice';
const _bobDid = 'did:test:bob';
const _mediatorDid = 'did:test:mediator';
const _roomId = '!roomABC:server';

Channel _fakeChannel() => Channel(
  offerLink: 'https://example.com/offer',
  publishOfferDid: _aliceDid,
  mediatorDid: _mediatorDid,
  status: ChannelStatus.inaugurated,
  contactCard: ContactCard(did: _aliceDid, type: 'individual', contactInfo: {}),
  type: ChannelType.individual,
  isConnectionInitiator: true,
  otherPartyPermanentChannelDid: _bobDid,
  permanentChannelDid: _aliceDid,
);

IndividualMatrixChatSDK _buildSdk({
  required _MockCoreSDK core,
  required _MockChatRepository repo,
}) => IndividualMatrixChatSDK(
  coreSDK: core,
  did: _aliceDid,
  otherPartyDid: _bobDid,
  mediatorDid: _mediatorDid,
  chatRepository: repo,
  options: MeetingPlaceChatSDKOptions(
    chatPresenceSendInterval: const Duration(hours: 1),
  ),
);

MatrixIncomingMessage _incoming({
  required String type,
  required String id,
  Map<String, dynamic>? content,
  DateTime? timestamp,
}) => MatrixIncomingMessage(
  senderDid: _bobDid,
  timestamp: timestamp ?? DateTime.utc(2026, 1, 1, 12),
  roomId: _roomId,
  eventId: id,
  type: type,
  content: content ?? {},
  isFromMe: false,
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MatrixRoomSubscription(
        receiverDid: '',
        options: TransportSubscriptionOptions(excludeSelf: true),
      ),
    );
    registerFallbackValue(const MatrixRoomHistoryQuery(receiverDid: ''));
    registerFallbackValue(_FakeOutgoingMessage());
    registerFallbackValue(
      Message(
        chatId: 'chat-id',
        messageId: 'msg-id',
        senderDid: 'did:test:sender',
        value: '',
        isFromMe: false,
        dateCreated: DateTime.utc(2026),
        status: ChatItemStatus.received,
      ),
    );
  });

  group('_advanceSyncMarker — sync-marker guard for ephemeral events', () {
    late _MockCoreSDK core;
    late _MockVdipClient vdip;
    late _MockVdipSubscription vdipSub;
    late _MockChatRepository repo;
    late IndividualMatrixChatSDK sdk;
    late StreamController<IncomingMessage> liveEvents;

    setUp(() {
      core = _MockCoreSDK();
      vdip = _MockVdipClient();
      vdipSub = _MockVdipSubscription();
      repo = _MockChatRepository();
      sdk = _buildSdk(core: core, repo: repo);
      liveEvents = StreamController<IncomingMessage>.broadcast();

      final channel = _fakeChannel();
      when(
        () => core.subscribe(any()),
      ).thenAnswer((_) async => _FakeHandle(liveEvents));
      when(() => core.vdip).thenReturn(vdip);
      when(
        () => core.getChannelByOtherPartyPermanentDid(_bobDid),
      ).thenAnswer((_) async => channel);
      when(() => vdip.subscribe(channel)).thenAnswer((_) async => vdipSub);
      when(() => vdip.incomingMessages).thenAnswer((_) => const Stream.empty());
      when(() => repo.listMessages(any())).thenAnswer((_) async => []);
      when(() => repo.getSyncMarker(any())).thenAnswer((_) async => null);
      when(
        () => repo.updateSyncMarker(
          chatId: any(named: 'chatId'),
          eventId: any(named: 'eventId'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => repo.createMessage(any()),
      ).thenAnswer((inv) async => inv.positionalArguments.first as ChatItem);
      // Bootstrap history stub — no events to replay.
      when(() => core.fetchHistory(any())).thenAnswer((_) async => []);
      when(() => core.sendMessage(any())).thenAnswer((_) async => null);
    });

    tearDown(() async {
      if (!liveEvents.isClosed) await liveEvents.close();
    });

    test('does not update sync marker when event type is m.typing', () async {
      await sdk.startChatSession();
      await Future<void>.delayed(Duration.zero);

      liveEvents.add(
        _incoming(
          type: 'm.typing',
          id: '${_roomId}_typing_$_bobDid',
          content: {
            'user_ids': [_bobDid],
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => repo.updateSyncMarker(
          chatId: any(named: 'chatId'),
          eventId: any(named: 'eventId'),
        ),
      );
    });

    test('updates sync marker for m.room.message events', () async {
      await sdk.startChatSession();
      await Future<void>.delayed(Duration.zero);

      const eventId = r'$real_matrix_event_id';
      liveEvents.add(
        _incoming(
          type: 'm.room.message',
          id: eventId,
          content: {'msgtype': 'm.text', 'body': 'hello'},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      verify(
        () => repo.updateSyncMarker(
          chatId: any(named: 'chatId'),
          eventId: eventId,
        ),
      ).called(1);
    });

    test('updates sync marker for m.receipt events', () async {
      await sdk.startChatSession();
      await Future<void>.delayed(Duration.zero);

      // m.receipt id is the id of the message that was read — a real event id.
      const eventId = r'$read_target_event_id';
      liveEvents.add(
        _incoming(
          type: 'm.receipt',
          id: eventId,
          content: {'event_id': eventId},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      verify(
        () => repo.updateSyncMarker(
          chatId: any(named: 'chatId'),
          eventId: eventId,
        ),
      ).called(1);
    });
  });
}
