import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockVdipClient extends Mock implements VdipClient {}

class _MockCoreSDKStreamSubscription extends Mock
    implements
        CoreSDKStreamSubscription<
          MediatorMessage,
          MediatorStreamProcessingResult
        > {}

class _MockChatRepository extends Mock implements ChatRepository {}

class _FakeHandle implements IncomingMessageHandle {
  _FakeHandle(this._controller);

  final StreamController<IncomingMessage> _controller;

  @override
  Stream<IncomingMessage> get stream => _controller.stream;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

const _aliceDid = 'did:test:alice';
const _bobDid = 'did:test:bob';
const _mediatorDid = 'did:test:mediator';

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

Message _persistedMessage(int i) => Message(
  chatId: Chat.deriveId(did: _aliceDid, otherPartyDid: _bobDid),
  messageId: 'local-$i',
  senderDid: _bobDid,
  value: 'persisted $i',
  isFromMe: false,
  dateCreated: DateTime.utc(2026, 1, 1, 0, i),
  status: ChatItemStatus.received,
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MatrixRoomSubscription(
        receiverDid: '',
        options: MatrixSubscriptionOptions(excludeSelf: true),
      ),
    );
  });

  group('MatrixChatSDK.startChatSession — non-blocking transport sync', () {
    late _MockCoreSDK core;
    late _MockVdipClient vdip;
    late _MockCoreSDKStreamSubscription vdipSubscription;
    late _MockChatRepository repo;
    late IndividualMatrixChatSDK sdk;
    late Completer<IncomingMessageHandle> subscribeCompleter;
    late StreamController<IncomingMessage> incomingController;
    late Channel channel;

    setUp(() {
      core = _MockCoreSDK();
      vdip = _MockVdipClient();
      vdipSubscription = _MockCoreSDKStreamSubscription();
      repo = _MockChatRepository();
      sdk = _buildSdk(core: core, repo: repo);
      channel = _fakeChannel();

      // Gate Matrix subscribe behind a completer we control. While it is
      // pending the SDK is "blocked on Matrix auth"; completing it lets
      // background bootstrap proceed.
      subscribeCompleter = Completer<IncomingMessageHandle>();
      incomingController = StreamController<IncomingMessage>.broadcast();

      when(
        () => core.subscribe(any()),
      ).thenAnswer((_) => subscribeCompleter.future);

      when(() => core.vdip).thenReturn(vdip);
      when(
        () => core.getChannelByOtherPartyPermanentDid(_bobDid),
      ).thenAnswer((_) async => channel);
      when(
        () => vdip.subscribe(channel),
      ).thenAnswer((_) async => vdipSubscription);
      when(() => vdip.incomingMessages).thenAnswer((_) => const Stream.empty());

      when(
        () => repo.listMessages(any()),
      ).thenAnswer((_) async => [_persistedMessage(1), _persistedMessage(2)]);

      when(() => repo.getSyncMarker(any())).thenAnswer((_) async => null);
    });

    tearDown(() async {
      if (!subscribeCompleter.isCompleted) {
        subscribeCompleter.complete(_FakeHandle(incomingController));
      }
      await incomingController.close();
    });

    test(
      'returns the persisted snapshot without waiting for Matrix subscribe',
      () async {
        // The crux: start the session, then race its completion against the
        // still-pending subscribe future. If startChatSession awaited the
        // transport, this Future.any would resolve to the sentinel and fail.
        final start = sdk.startChatSession();
        final sentinel = Future<String>.delayed(
          const Duration(seconds: 1),
          () => 'still-blocked-on-subscribe',
        );

        final winner = await Future.any<Object>([start, sentinel]);

        expect(
          winner,
          isA<Chat>(),
          reason:
              'startChatSession must return before the Matrix subscribe '
              'future completes — the new flow runs that in the background.',
        );
        expect(subscribeCompleter.isCompleted, isFalse);

        final chat = winner as Chat;
        expect(chat.messages, hasLength(2));
      },
    );

    test('chatStreamSubscription resolves before Matrix subscribe completes, '
        'so the app can attach a listener immediately', () async {
      await sdk.startChatSession();

      // subscribe completer is intentionally still pending here.
      expect(subscribeCompleter.isCompleted, isFalse);

      final sentinel = Future<String>.delayed(
        const Duration(seconds: 1),
        () => 'still-blocked-on-subscribe',
      );

      final winner = await Future.any<Object?>([
        sdk.chatStreamSubscription,
        sentinel,
      ]);

      expect(
        winner,
        isA<ChatStream>(),
        reason:
            'chatStreamSubscription must not await the transport — it '
            'relies on ChatStream\'s buffer-until-listener guarantee.',
      );
      expect(subscribeCompleter.isCompleted, isFalse);
    });

    test('events pushed before a listener attaches are flushed once it does, '
        'so fast local sends are not lost during background sync', () async {
      await sdk.startChatSession();

      // Simulate the app sending a message before the listener is attached
      // (e.g. the user tapped send immediately after opening the chat).
      final eager = _persistedMessage(99);
      sdk.chatStream.pushData(StreamData(chatItem: eager));

      final stream = await sdk.chatStreamSubscription;
      expect(stream, isNotNull);

      final received = await stream!.stream.first.timeout(
        const Duration(seconds: 1),
        onTimeout: () => throw StateError(
          'Buffered event was not flushed to the late-attached listener',
        ),
      );

      expect(received.chatItem, same(eager));
    });
  });

  group('IndividualMatrixChatSDK._subscribeToIssuedCredentials', () {
    late _MockCoreSDK core;
    late _MockVdipClient vdip;
    late _MockCoreSDKStreamSubscription vdipSubscription;
    late _MockChatRepository repo;
    late IndividualMatrixChatSDK sdk;
    late Completer<IncomingMessageHandle> subscribeCompleter;
    late StreamController<IncomingMessage> incomingController;
    late StreamController<PlainTextMessage> vdipIncomingController;
    late Channel channel;

    setUp(() {
      core = _MockCoreSDK();
      vdip = _MockVdipClient();
      vdipSubscription = _MockCoreSDKStreamSubscription();
      repo = _MockChatRepository();
      sdk = _buildSdk(core: core, repo: repo);
      channel = _fakeChannel();

      subscribeCompleter = Completer<IncomingMessageHandle>();
      incomingController = StreamController<IncomingMessage>.broadcast();
      vdipIncomingController = StreamController<PlainTextMessage>.broadcast();

      when(() => core.subscribe(any())).thenAnswer((_) => subscribeCompleter.future);
      when(() => core.vdip).thenReturn(vdip);
      when(
        () => core.getChannelByOtherPartyPermanentDid(_bobDid),
      ).thenAnswer((_) async => channel);
      when(() => vdip.subscribe(channel)).thenAnswer((_) async => vdipSubscription);
      when(() => vdip.incomingMessages).thenAnswer((_) => vdipIncomingController.stream);
      when(() => core.updateChannel(channel)).thenAnswer((_) async {});
      when(() => repo.listMessages(any())).thenAnswer((_) async => []);
      when(() => repo.getSyncMarker(any())).thenAnswer((_) async => null);
    });

    tearDown(() async {
      if (!subscribeCompleter.isCompleted) {
        subscribeCompleter.complete(_FakeHandle(incomingController));
      }
      await incomingController.close();
      await vdipIncomingController.close();
    });

    test('updates messageSyncMarker and persists channel when issued credential arrives', () async {
      await sdk.startChatSession();
      await Future<void>.delayed(Duration.zero); // drain .then() microtask

      final createdTime = DateTime.utc(2026, 6, 18, 12);
      vdipIncomingController.add(
        PlainTextMessage(
          id: const Uuid().v4(),
          type: Uri.parse(VdipClient.issuedCredentialMessageType),
          body: {},
          createdTime: createdTime,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(channel.messageSyncMarker, equals(createdTime));
      verify(() => core.updateChannel(channel)).called(1);
    });

    test('does not update channel when message has no createdTime', () async {
      await sdk.startChatSession();
      await Future<void>.delayed(Duration.zero);

      vdipIncomingController.add(
        PlainTextMessage(
          id: const Uuid().v4(),
          type: Uri.parse(VdipClient.issuedCredentialMessageType),
          body: {},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(channel.messageSyncMarker, isNull);
      verifyNever(() => core.updateChannel(channel));
    });

    test('does not regress marker when incoming createdTime is older than existing', () async {
      final existingMarker = DateTime.utc(2026, 6, 18, 12);
      channel.messageSyncMarker = existingMarker;

      await sdk.startChatSession();
      await Future<void>.delayed(Duration.zero);

      vdipIncomingController.add(
        PlainTextMessage(
          id: const Uuid().v4(),
          type: Uri.parse(VdipClient.issuedCredentialMessageType),
          body: {},
          createdTime: DateTime.utc(2026, 6, 18, 11),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(channel.messageSyncMarker, equals(existingMarker));
      verifyNever(() => core.updateChannel(channel));
    });

    test('ignores non-issuedCredential messages on incomingMessages', () async {
      await sdk.startChatSession();
      await Future<void>.delayed(Duration.zero);

      vdipIncomingController.add(
        PlainTextMessage(
          id: const Uuid().v4(),
          type: Uri.parse(VdipClient.requestIssuanceMessageType),
          body: {},
          createdTime: DateTime.utc(2026, 6, 18, 12),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(channel.messageSyncMarker, isNull);
      verifyNever(() => core.updateChannel(channel));
    });
  });
}
