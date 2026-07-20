import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/call/mpx_call_event_type.dart';
import 'package:meeting_place_matrix/src/exceptions/meeting_place_livekit_call_exception.dart';
import 'package:meeting_place_matrix/src/matrix_room_event.dart';
import 'package:meeting_place_matrix/src/matrix_subscription_options.dart';
import 'package:meeting_place_matrix/src/meeting_place_livekit_call_plugin.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'fakes/fake_fallbacks.dart';
import 'fakes/fake_livekit_service.dart';
import 'mocks/mocks.dart';

MeetingPlaceLiveKitCallPlugin _plugin({
  Uri? livekitServiceUrl,
  LiveKitRoomFactory? roomFactory,
}) => MeetingPlaceLiveKitCallPlugin(
  livekitServiceUrl:
      livekitServiceUrl ?? Uri.parse('https://livekit.example.com'),
  sfuAllowedHosts: const ['livekit.example.com'],
  rtcDelegate: FakeWebRTCDelegate(),
  roomFactory: roomFactory ?? fakeLiveKitRoomFactory(),
);

MockMeetingPlaceMatrixSDK _mockSdk() {
  final sdk = MockMeetingPlaceMatrixSDK();
  when(() => sdk.matrixService).thenReturn(MockMatrixService());
  when(() => sdk.callSignals).thenAnswer((_) => const Stream.empty());
  when(
    () => sdk.getChannelByOtherPartyPermanentDid(any()),
  ).thenThrow(Exception('stub: not needed for this test'));
  return sdk;
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDidManager());
    registerFallbackValue(FakeChannel());
    registerFallbackValue(const MatrixSubscriptionOptions());
  });

  group('isSupported', () {
    test('returns true when livekitServiceUrl host is non-empty', () {
      final plugin = _plugin(
        livekitServiceUrl: Uri.parse('https://livekit.example.com'),
      );
      expect(plugin.isSupported, isTrue);
    });

    test('returns false when livekitServiceUrl host is empty', () {
      final plugin = _plugin(livekitServiceUrl: Uri());
      expect(plugin.isSupported, isFalse);
    });
  });

  group('incomingCalls', () {
    test('is a broadcast stream — multiple listeners do not throw', () {
      final plugin = _plugin();
      final stream = plugin.incomingCalls;

      final sub1 = stream.listen((_) {});
      final sub2 = stream.listen((_) {});

      addTearDown(() {
        sub1.cancel();
        sub2.cancel();
      });
    });
  });

  group('acceptCall', () {
    test('throws for an unknown callId', () async {
      final plugin = _plugin();
      await expectLater(
        plugin.acceptCall(callId: 'unknown-call'),
        throwsA(isA<MeetingPlaceLiveKitCallOperationException>()),
      );
    });
  });

  group('declineCall', () {
    test('completes without throwing for an unknown callId', () async {
      final plugin = _plugin();
      await expectLater(plugin.declineCall(callId: 'unknown-call'), completes);
    });
  });

  group('pending incoming group calls', () {
    test('emit cancelledCalls when decline arrives before incoming banner'
        ' emission', () async {
      const ownDid = 'did:key:group';
      const callerDid = 'did:key:caller';
      const callId = '!room:example.com@123';

      final sdk = MockMeetingPlaceMatrixSDK();
      final matrixService = MockMatrixService();
      final signalController = StreamController<CallSignal>.broadcast();
      final didManagerCompleter = Completer<DidManager>();

      when(() => sdk.matrixService).thenReturn(matrixService);
      when(() => sdk.callSignals).thenAnswer((_) => signalController.stream);
      when(() => sdk.getChannelByDid(ownDid)).thenAnswer(
        (_) async => Channel(
          offerLink: 'offer-link',
          publishOfferDid: 'did:key:publishOffer',
          mediatorDid: 'did:key:mediator',
          status: ChannelStatus.inaugurated,
          contactCard: ContactCard(
            did: 'did:key:contact',
            type: 'group',
            contactInfo: const {},
          ),
          type: ChannelType.group,
          isConnectionInitiator: false,
          permanentChannelDid: ownDid,
          otherPartyPermanentChannelDid: callerDid,
        ),
      );
      when(
        () => sdk.getDidManager(ownDid),
      ).thenAnswer((_) => didManagerCompleter.future);
      when(
        () => matrixService.resolveRoomIdForChannel(
          didManager: any(named: 'didManager'),
          channel: any(named: 'channel'),
        ),
      ).thenAnswer((_) async => '!room:example.com');
      when(
        () => matrixService.activeCallId(
          didManager: any(named: 'didManager'),
          roomId: any(named: 'roomId'),
        ),
      ).thenAnswer((_) async => callId);

      final plugin = _plugin();
      plugin.initialize(sdk: sdk);
      addTearDown(() async {
        await plugin.dispose();
        await signalController.close();
      });

      final incomingFuture = plugin.incomingCalls.first;
      final cancelledFuture = plugin.cancelledCalls.first;

      signalController.add(
        const IncomingCallSignal(
          ownChannelDid: ownDid,
          mediaType: CallMediaType.audio,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      signalController.add(
        const CallDeclineSignal(
          ownChannelDid: ownDid,
          otherPartyPermanentChannelDid: callerDid,
        ),
      );

      final didManager = MockDidManager();
      didManagerCompleter.complete(didManager);

      final cancelled = await cancelledFuture.timeout(
        const Duration(seconds: 1),
      );

      expect(cancelled.callerPermanentChannelDid, callerDid);
      expect(cancelled.otherPartyPermanentChannelDid, ownDid);
      await expectLater(
        incomingFuture.timeout(const Duration(milliseconds: 100)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test(
      'emit cancelledCalls when Matrix call membership disappears',
      () async {
        const ownDid = 'did:key:group';
        const callerDid = 'did:key:caller';
        const callId = '!room:example.com@123';

        final sdk = MockMeetingPlaceMatrixSDK();
        final matrixService = MockMatrixService();
        final signalController = StreamController<CallSignal>.broadcast();
        final watchController = StreamController<Object?>.broadcast();

        when(() => sdk.matrixService).thenReturn(matrixService);
        when(() => sdk.callSignals).thenAnswer((_) => signalController.stream);
        when(() => sdk.getChannelByDid(ownDid)).thenAnswer(
          (_) async => Channel(
            offerLink: 'offer-link',
            publishOfferDid: 'did:key:publishOffer',
            mediatorDid: 'did:key:mediator',
            status: ChannelStatus.inaugurated,
            contactCard: ContactCard(
              did: 'did:key:contact',
              type: 'group',
              contactInfo: const {},
            ),
            type: ChannelType.group,
            isConnectionInitiator: false,
            permanentChannelDid: ownDid,
            otherPartyPermanentChannelDid: callerDid,
          ),
        );
        when(
          () => sdk.getDidManager(any()),
        ).thenAnswer((_) async => MockDidManager());
        when(
          () => matrixService.resolveRoomIdForChannel(
            didManager: any(named: 'didManager'),
            channel: any(named: 'channel'),
          ),
        ).thenAnswer((_) async => '!room:example.com');
        when(
          () => matrixService.activeCallId(
            didManager: any(named: 'didManager'),
            roomId: any(named: 'roomId'),
          ),
        ).thenAnswer((_) async => callId);
        when(
          () => matrixService.watchIncomingCall(roomId: '!room:example.com'),
        ).thenAnswer((_) => watchController.stream.map((_) {}));

        final plugin = _plugin();
        plugin.initialize(sdk: sdk);
        addTearDown(() async {
          await plugin.dispose();
          await signalController.close();
          await watchController.close();
        });

        final cancelledFuture = plugin.cancelledCalls.first;

        signalController.add(
          const IncomingCallSignal(
            ownChannelDid: ownDid,
            mediaType: CallMediaType.audio,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await watchController.close();

        final cancelled = await cancelledFuture.timeout(
          const Duration(seconds: 1),
        );
        expect(cancelled.callId, callId);
        expect(cancelled.callerPermanentChannelDid, callerDid);
        expect(cancelled.otherPartyPermanentChannelDid, callerDid);
        expect(cancelled.mediaType, CallMediaType.audio);
      },
    );

    test(
      'emit cancelledCalls when a Matrix call-cancel event arrives',
      () async {
        const ownDid = 'did:key:group';
        const callerDid = 'did:key:caller';
        const callId = '!room:example.com@123';

        final sdk = MockMeetingPlaceMatrixSDK();
        final matrixService = MockMatrixService();
        final signalController = StreamController<CallSignal>.broadcast();
        final watchController = StreamController<Object?>.broadcast();
        final roomEventController = StreamController<MatrixRoomEvent>();
        final didManager = MockDidManager();

        when(() => sdk.matrixService).thenReturn(matrixService);
        when(() => sdk.callSignals).thenAnswer((_) => signalController.stream);
        when(() => sdk.getChannelByDid(ownDid)).thenAnswer(
          (_) async => Channel(
            offerLink: 'offer-link',
            publishOfferDid: 'did:key:publishOffer',
            mediatorDid: 'did:key:mediator',
            status: ChannelStatus.inaugurated,
            contactCard: ContactCard(
              did: 'did:key:contact',
              type: 'group',
              contactInfo: const {},
            ),
            type: ChannelType.group,
            isConnectionInitiator: false,
            permanentChannelDid: ownDid,
            otherPartyPermanentChannelDid: callerDid,
          ),
        );
        when(
          () => sdk.getDidManager(ownDid),
        ).thenAnswer((_) async => didManager);
        when(
          () => matrixService.resolveRoomIdForChannel(
            didManager: any(named: 'didManager'),
            channel: any(named: 'channel'),
          ),
        ).thenAnswer((_) async => '!room:example.com');
        when(
          () => matrixService.activeCallId(
            didManager: any(named: 'didManager'),
            roomId: any(named: 'roomId'),
          ),
        ).thenAnswer((_) async => callId);
        when(
          () => matrixService.watchIncomingCall(roomId: '!room:example.com'),
        ).thenAnswer((_) => watchController.stream.map((_) {}));
        when(
          () => matrixService.subscribeToRoom(
            '!room:example.com',
            didManager: didManager,
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) => roomEventController.stream);

        final plugin = _plugin();
        plugin.initialize(sdk: sdk);
        addTearDown(() async {
          await plugin.dispose();
          await signalController.close();
          await watchController.close();
          await roomEventController.close();
        });

        final incomingFuture = plugin.incomingCalls.first;
        final cancelledFuture = plugin.cancelledCalls.first;

        signalController.add(
          const IncomingCallSignal(
            ownChannelDid: ownDid,
            mediaType: CallMediaType.audio,
          ),
        );
        await incomingFuture.timeout(const Duration(seconds: 1));
        await Future<void>.delayed(Duration.zero);
        final freshTimestamp = DateTime.now().toUtc();

        roomEventController.add(
          MatrixRoomEvent(
            id: 'cancel-event-id',
            type: MpxCallEventType.callCancel,
            senderDid: callerDid,
            roomId: '!room:example.com',
            content: const {
              'callerPermanentChannelDid': callerDid,
              'callId': callId,
            },
            timestamp: freshTimestamp,
          ),
        );

        final cancelled = await cancelledFuture.timeout(
          const Duration(seconds: 1),
        );
        expect(cancelled.callId, callId);
        expect(cancelled.callerPermanentChannelDid, callerDid);
        expect(cancelled.otherPartyPermanentChannelDid, callerDid);
        expect(cancelled.mediaType, CallMediaType.audio);
      },
    );

    test(
      'ignore stale call-cancel event for different call generation in room',
      () async {
        const ownDid = 'did:key:group';
        const callerDid = 'did:key:caller';

        final sdk = MockMeetingPlaceMatrixSDK();
        final matrixService = MockMatrixService();
        final signalController = StreamController<CallSignal>.broadcast();
        final roomEventController = StreamController<MatrixRoomEvent>();
        final didManager = MockDidManager();

        when(() => sdk.matrixService).thenReturn(matrixService);
        when(() => sdk.callSignals).thenAnswer((_) => signalController.stream);
        when(() => sdk.getChannelByDid(ownDid)).thenAnswer(
          (_) async => Channel(
            offerLink: 'offer-link',
            publishOfferDid: 'did:key:publishOffer',
            mediatorDid: 'did:key:mediator',
            status: ChannelStatus.inaugurated,
            contactCard: ContactCard(
              did: 'did:key:contact',
              type: 'group',
              contactInfo: const {},
            ),
            type: ChannelType.group,
            isConnectionInitiator: false,
            permanentChannelDid: ownDid,
            otherPartyPermanentChannelDid: callerDid,
          ),
        );
        when(
          () => sdk.getDidManager(ownDid),
        ).thenAnswer((_) async => didManager);
        when(
          () => matrixService.resolveRoomIdForChannel(
            didManager: any(named: 'didManager'),
            channel: any(named: 'channel'),
          ),
        ).thenAnswer((_) async => '!room:example.com');
        when(
          () => matrixService.activeCallId(
            didManager: any(named: 'didManager'),
            roomId: any(named: 'roomId'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => matrixService.watchIncomingCall(roomId: '!room:example.com'),
        ).thenReturn(null);
        when(
          () => matrixService.subscribeToRoom(
            '!room:example.com',
            didManager: didManager,
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) => roomEventController.stream);

        final plugin = _plugin();
        plugin.initialize(sdk: sdk);
        addTearDown(() async {
          await plugin.dispose();
          await signalController.close();
          await roomEventController.close();
        });

        final incomingFuture = plugin.incomingCalls.first;

        signalController.add(
          const IncomingCallSignal(
            ownChannelDid: ownDid,
            mediaType: CallMediaType.audio,
          ),
        );
        await incomingFuture.timeout(const Duration(seconds: 1));
        await Future<void>.delayed(Duration.zero);

        roomEventController.add(
          MatrixRoomEvent(
            id: 'stale-cancel-event-id',
            type: MpxCallEventType.callCancel,
            senderDid: callerDid,
            roomId: '!room:example.com',
            content: const {
              'callerPermanentChannelDid': callerDid,
              'callId': '!room:example.com@old-generation',
            },
            timestamp: DateTime(2024),
          ),
        );

        await expectLater(
          plugin.cancelledCalls.first.timeout(
            const Duration(milliseconds: 100),
          ),
          throwsA(isA<TimeoutException>()),
        );
      },
    );

    test(
      'ignore cancel without callId from different caller on fallback roomId',
      () async {
        const ownDid = 'did:key:group';
        const callerDid = 'did:key:caller';
        const otherCallerDid = 'did:key:other-caller';

        final sdk = MockMeetingPlaceMatrixSDK();
        final matrixService = MockMatrixService();
        final signalController = StreamController<CallSignal>.broadcast();
        final roomEventController = StreamController<MatrixRoomEvent>();
        final didManager = MockDidManager();

        when(() => sdk.matrixService).thenReturn(matrixService);
        when(() => sdk.callSignals).thenAnswer((_) => signalController.stream);
        when(() => sdk.getChannelByDid(ownDid)).thenAnswer(
          (_) async => Channel(
            offerLink: 'offer-link',
            publishOfferDid: 'did:key:publishOffer',
            mediatorDid: 'did:key:mediator',
            status: ChannelStatus.inaugurated,
            contactCard: ContactCard(
              did: 'did:key:contact',
              type: 'group',
              contactInfo: const {},
            ),
            type: ChannelType.group,
            isConnectionInitiator: false,
            permanentChannelDid: ownDid,
            otherPartyPermanentChannelDid: callerDid,
          ),
        );
        when(
          () => sdk.getDidManager(ownDid),
        ).thenAnswer((_) async => didManager);
        when(
          () => matrixService.resolveRoomIdForChannel(
            didManager: any(named: 'didManager'),
            channel: any(named: 'channel'),
          ),
        ).thenAnswer((_) async => '!room:example.com');
        when(
          () => matrixService.activeCallId(
            didManager: any(named: 'didManager'),
            roomId: any(named: 'roomId'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => matrixService.watchIncomingCall(roomId: '!room:example.com'),
        ).thenAnswer((_) => const Stream<void>.empty());
        when(
          () => matrixService.subscribeToRoom(
            '!room:example.com',
            didManager: didManager,
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) => roomEventController.stream);

        final plugin = _plugin();
        plugin.initialize(sdk: sdk);
        addTearDown(() async {
          await plugin.dispose();
          await signalController.close();
          await roomEventController.close();
        });

        final incomingFuture = plugin.incomingCalls.first;

        signalController.add(
          const IncomingCallSignal(
            ownChannelDid: ownDid,
            mediaType: CallMediaType.audio,
          ),
        );
        final incoming = await incomingFuture.timeout(
          const Duration(seconds: 1),
        );

        expect(incoming.callId, '!room:example.com');

        roomEventController.add(
          MatrixRoomEvent(
            id: 'legacy-cancel-event-id',
            type: MpxCallEventType.callCancel,
            senderDid: otherCallerDid,
            roomId: '!room:example.com',
            content: const {'callerPermanentChannelDid': otherCallerDid},
            timestamp: DateTime(2024),
          ),
        );

        await expectLater(
          plugin.cancelledCalls.first.timeout(
            const Duration(milliseconds: 100),
          ),
          throwsA(isA<TimeoutException>()),
        );
      },
    );

    test(
      'emit cancelled call from room event without callId matching fallback',
      () async {
        const ownDid = 'did:key:group';
        const callerDid = 'did:key:caller';

        final sdk = MockMeetingPlaceMatrixSDK();
        final matrixService = MockMatrixService();
        final signalController = StreamController<CallSignal>.broadcast();
        final roomEventController = StreamController<MatrixRoomEvent>();
        final didManager = MockDidManager();

        when(() => sdk.matrixService).thenReturn(matrixService);
        when(() => sdk.callSignals).thenAnswer((_) => signalController.stream);
        when(() => sdk.getChannelByDid(ownDid)).thenAnswer(
          (_) async => Channel(
            offerLink: 'offer-link',
            publishOfferDid: 'did:key:publishOffer',
            mediatorDid: 'did:key:mediator',
            status: ChannelStatus.inaugurated,
            contactCard: ContactCard(
              did: 'did:key:contact',
              type: 'group',
              contactInfo: const {},
            ),
            type: ChannelType.group,
            isConnectionInitiator: false,
            permanentChannelDid: ownDid,
            otherPartyPermanentChannelDid: callerDid,
          ),
        );
        when(
          () => sdk.getDidManager(ownDid),
        ).thenAnswer((_) async => didManager);
        when(
          () => matrixService.resolveRoomIdForChannel(
            didManager: any(named: 'didManager'),
            channel: any(named: 'channel'),
          ),
        ).thenAnswer((_) async => '!room:example.com');
        when(
          () => matrixService.activeCallId(
            didManager: any(named: 'didManager'),
            roomId: any(named: 'roomId'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => matrixService.watchIncomingCall(roomId: '!room:example.com'),
        ).thenAnswer((_) => const Stream<void>.empty());
        when(
          () => matrixService.subscribeToRoom(
            '!room:example.com',
            didManager: didManager,
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) => roomEventController.stream);

        final plugin = _plugin();
        plugin.initialize(sdk: sdk);
        addTearDown(() async {
          await plugin.dispose();
          await signalController.close();
          await roomEventController.close();
        });

        final incomingFuture = plugin.incomingCalls.first;
        final cancelledFuture = plugin.cancelledCalls.first;

        signalController.add(
          const IncomingCallSignal(
            ownChannelDid: ownDid,
            mediaType: CallMediaType.audio,
          ),
        );
        final incoming = await incomingFuture.timeout(
          const Duration(seconds: 1),
        );

        expect(incoming.callId, '!room:example.com');

        final freshTimestamp = DateTime.now().toUtc();

        roomEventController.add(
          MatrixRoomEvent(
            id: 'matching-legacy-cancel-event-id',
            type: MpxCallEventType.callCancel,
            senderDid: callerDid,
            roomId: '!room:example.com',
            content: const {'callerPermanentChannelDid': callerDid},
            timestamp: freshTimestamp,
          ),
        );

        final cancelled = await cancelledFuture.timeout(
          const Duration(seconds: 1),
        );
        expect(cancelled.callId, '!room:example.com');
        expect(cancelled.callerPermanentChannelDid, callerDid);
        expect(cancelled.otherPartyPermanentChannelDid, callerDid);
        expect(cancelled.mediaType, CallMediaType.audio);
      },
    );

    test(
      'emit cancelled call when fallback roomId gets resolved callId cancel',
      () async {
        const ownDid = 'did:key:group';
        const callerDid = 'did:key:caller';
        const resolvedCallId = '!room:example.com@123456';

        final sdk = MockMeetingPlaceMatrixSDK();
        final matrixService = MockMatrixService();
        final signalController = StreamController<CallSignal>.broadcast();
        final roomEventController = StreamController<MatrixRoomEvent>();
        final didManager = MockDidManager();

        when(() => sdk.matrixService).thenReturn(matrixService);
        when(() => sdk.callSignals).thenAnswer((_) => signalController.stream);
        when(() => sdk.getChannelByDid(ownDid)).thenAnswer(
          (_) async => Channel(
            offerLink: 'offer-link',
            publishOfferDid: 'did:key:publishOffer',
            mediatorDid: 'did:key:mediator',
            status: ChannelStatus.inaugurated,
            contactCard: ContactCard(
              did: 'did:key:contact',
              type: 'group',
              contactInfo: const {},
            ),
            type: ChannelType.group,
            isConnectionInitiator: false,
            permanentChannelDid: ownDid,
            otherPartyPermanentChannelDid: callerDid,
          ),
        );
        when(
          () => sdk.getDidManager(ownDid),
        ).thenAnswer((_) async => didManager);
        when(
          () => matrixService.resolveRoomIdForChannel(
            didManager: any(named: 'didManager'),
            channel: any(named: 'channel'),
          ),
        ).thenAnswer((_) async => '!room:example.com');
        when(
          () => matrixService.activeCallId(
            didManager: any(named: 'didManager'),
            roomId: any(named: 'roomId'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => matrixService.watchIncomingCall(roomId: '!room:example.com'),
        ).thenAnswer((_) => const Stream<void>.empty());
        when(
          () => matrixService.subscribeToRoom(
            '!room:example.com',
            didManager: didManager,
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) => roomEventController.stream);

        final plugin = _plugin();
        plugin.initialize(sdk: sdk);
        addTearDown(() async {
          await plugin.dispose();
          await signalController.close();
          await roomEventController.close();
        });

        final incomingFuture = plugin.incomingCalls.first;
        final cancelledFuture = plugin.cancelledCalls.first;

        signalController.add(
          const IncomingCallSignal(
            ownChannelDid: ownDid,
            mediaType: CallMediaType.audio,
          ),
        );
        final incoming = await incomingFuture.timeout(
          const Duration(seconds: 1),
        );

        expect(incoming.callId, '!room:example.com');

        final freshTimestamp = DateTime.now().toUtc();

        roomEventController.add(
          MatrixRoomEvent(
            id: 'resolved-call-id-cancel-event-id',
            type: MpxCallEventType.callCancel,
            senderDid: callerDid,
            roomId: '!room:example.com',
            content: const {
              'callerPermanentChannelDid': callerDid,
              'callId': resolvedCallId,
            },
            timestamp: freshTimestamp,
          ),
        );

        final cancelled = await cancelledFuture.timeout(
          const Duration(seconds: 1),
        );
        expect(cancelled.callId, '!room:example.com');
        expect(cancelled.callerPermanentChannelDid, callerDid);
        expect(cancelled.otherPartyPermanentChannelDid, callerDid);
        expect(cancelled.mediaType, CallMediaType.audio);
      },
    );

    test(
      'ignore stale room cancel event older than pending watcher start time',
      () async {
        const ownDid = 'did:key:group';
        const callerDid = 'did:key:caller';

        final sdk = MockMeetingPlaceMatrixSDK();
        final matrixService = MockMatrixService();
        final signalController = StreamController<CallSignal>.broadcast();
        final roomEventController = StreamController<MatrixRoomEvent>();
        final didManager = MockDidManager();

        when(() => sdk.matrixService).thenReturn(matrixService);
        when(() => sdk.callSignals).thenAnswer((_) => signalController.stream);
        when(() => sdk.getChannelByDid(ownDid)).thenAnswer(
          (_) async => Channel(
            offerLink: 'offer-link',
            publishOfferDid: 'did:key:publishOffer',
            mediatorDid: 'did:key:mediator',
            status: ChannelStatus.inaugurated,
            contactCard: ContactCard(
              did: 'did:key:contact',
              type: 'group',
              contactInfo: const {},
            ),
            type: ChannelType.group,
            isConnectionInitiator: false,
            permanentChannelDid: ownDid,
            otherPartyPermanentChannelDid: callerDid,
          ),
        );
        when(
          () => sdk.getDidManager(ownDid),
        ).thenAnswer((_) async => didManager);
        when(
          () => matrixService.resolveRoomIdForChannel(
            didManager: any(named: 'didManager'),
            channel: any(named: 'channel'),
          ),
        ).thenAnswer((_) async => '!room:example.com');
        when(
          () => matrixService.activeCallId(
            didManager: any(named: 'didManager'),
            roomId: any(named: 'roomId'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => matrixService.watchIncomingCall(roomId: '!room:example.com'),
        ).thenAnswer((_) => const Stream<void>.empty());
        when(
          () => matrixService.subscribeToRoom(
            '!room:example.com',
            didManager: didManager,
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) => roomEventController.stream);

        final plugin = _plugin();
        plugin.initialize(sdk: sdk);
        addTearDown(() async {
          await plugin.dispose();
          await signalController.close();
          await roomEventController.close();
        });

        final incomingFuture = plugin.incomingCalls.first;

        signalController.add(
          const IncomingCallSignal(
            ownChannelDid: ownDid,
            mediaType: CallMediaType.audio,
          ),
        );
        final incoming = await incomingFuture.timeout(
          const Duration(seconds: 1),
        );

        expect(incoming.callId, '!room:example.com');

        roomEventController.add(
          MatrixRoomEvent(
            id: 'stale-timestamp-cancel-event-id',
            type: MpxCallEventType.callCancel,
            senderDid: callerDid,
            roomId: '!room:example.com',
            content: const {'callerPermanentChannelDid': callerDid},
            timestamp: DateTime(2000),
          ),
        );

        await expectLater(
          plugin.cancelledCalls.first.timeout(
            const Duration(milliseconds: 100),
          ),
          throwsA(isA<TimeoutException>()),
        );
      },
    );

    test(
      'emit cancelled call from cancel event when watchIncomingCall unavail',
      () async {
        const ownDid = 'did:key:group';
        const callerDid = 'did:key:caller';
        const callId = '!room:example.com@123';

        final sdk = MockMeetingPlaceMatrixSDK();
        final matrixService = MockMatrixService();
        final signalController = StreamController<CallSignal>.broadcast();
        final roomEventController = StreamController<MatrixRoomEvent>();
        final didManager = MockDidManager();

        when(() => sdk.matrixService).thenReturn(matrixService);
        when(() => sdk.callSignals).thenAnswer((_) => signalController.stream);
        when(() => sdk.getChannelByDid(ownDid)).thenAnswer(
          (_) async => Channel(
            offerLink: 'offer-link',
            publishOfferDid: 'did:key:publishOffer',
            mediatorDid: 'did:key:mediator',
            status: ChannelStatus.inaugurated,
            contactCard: ContactCard(
              did: 'did:key:contact',
              type: 'group',
              contactInfo: const {},
            ),
            type: ChannelType.group,
            isConnectionInitiator: false,
            permanentChannelDid: ownDid,
            otherPartyPermanentChannelDid: callerDid,
          ),
        );
        when(
          () => sdk.getDidManager(ownDid),
        ).thenAnswer((_) async => didManager);
        when(
          () => matrixService.resolveRoomIdForChannel(
            didManager: any(named: 'didManager'),
            channel: any(named: 'channel'),
          ),
        ).thenAnswer((_) async => '!room:example.com');
        when(
          () => matrixService.activeCallId(
            didManager: any(named: 'didManager'),
            roomId: any(named: 'roomId'),
          ),
        ).thenAnswer((_) async => callId);
        when(
          () => matrixService.watchIncomingCall(roomId: '!room:example.com'),
        ).thenReturn(null);
        when(
          () => matrixService.subscribeToRoom(
            '!room:example.com',
            didManager: didManager,
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) => roomEventController.stream);

        final plugin = _plugin();
        plugin.initialize(sdk: sdk);
        addTearDown(() async {
          await plugin.dispose();
          await signalController.close();
          await roomEventController.close();
        });

        final incomingFuture = plugin.incomingCalls.first;
        final cancelledFuture = plugin.cancelledCalls.first;

        signalController.add(
          const IncomingCallSignal(
            ownChannelDid: ownDid,
            mediaType: CallMediaType.audio,
          ),
        );
        await incomingFuture.timeout(const Duration(seconds: 1));
        await Future<void>.delayed(Duration.zero);
        final freshTimestamp = DateTime.now().toUtc();

        roomEventController.add(
          MatrixRoomEvent(
            id: 'cancel-event-id',
            type: MpxCallEventType.callCancel,
            senderDid: callerDid,
            roomId: '!room:example.com',
            content: const {'callerPermanentChannelDid': callerDid},
            timestamp: freshTimestamp,
          ),
        );

        final cancelled = await cancelledFuture.timeout(
          const Duration(seconds: 1),
        );
        expect(cancelled.callId, callId);
        expect(cancelled.callerPermanentChannelDid, callerDid);
        expect(cancelled.otherPartyPermanentChannelDid, callerDid);
        expect(cancelled.mediaType, CallMediaType.audio);
      },
    );

    test(
      'do not cancel pending invite when membership gone, callId fallback',
      () async {
        const ownDid = 'did:key:group';
        const callerDid = 'did:key:caller';

        final sdk = MockMeetingPlaceMatrixSDK();
        final matrixService = MockMatrixService();
        final signalController = StreamController<CallSignal>.broadcast();
        final watchController = StreamController<Object?>.broadcast();
        final roomEventController = StreamController<MatrixRoomEvent>();
        final didManager = MockDidManager();

        when(() => sdk.matrixService).thenReturn(matrixService);
        when(() => sdk.callSignals).thenAnswer((_) => signalController.stream);
        when(() => sdk.getChannelByDid(ownDid)).thenAnswer(
          (_) async => Channel(
            offerLink: 'offer-link',
            publishOfferDid: 'did:key:publishOffer',
            mediatorDid: 'did:key:mediator',
            status: ChannelStatus.inaugurated,
            contactCard: ContactCard(
              did: 'did:key:contact',
              type: 'group',
              contactInfo: const {},
            ),
            type: ChannelType.group,
            isConnectionInitiator: false,
            permanentChannelDid: ownDid,
            otherPartyPermanentChannelDid: callerDid,
          ),
        );
        when(
          () => sdk.getDidManager(ownDid),
        ).thenAnswer((_) async => didManager);
        when(
          () => matrixService.resolveRoomIdForChannel(
            didManager: any(named: 'didManager'),
            channel: any(named: 'channel'),
          ),
        ).thenAnswer((_) async => '!room:example.com');
        when(
          () => matrixService.activeCallId(
            didManager: any(named: 'didManager'),
            roomId: any(named: 'roomId'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => matrixService.watchIncomingCall(roomId: '!room:example.com'),
        ).thenAnswer((_) => watchController.stream.map((_) {}));
        when(
          () => matrixService.subscribeToRoom(
            '!room:example.com',
            didManager: didManager,
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) => roomEventController.stream);

        final plugin = _plugin();
        plugin.initialize(sdk: sdk);
        addTearDown(() async {
          await plugin.dispose();
          await signalController.close();
          await watchController.close();
          await roomEventController.close();
        });

        final incomingFuture = plugin.incomingCalls.first;

        signalController.add(
          const IncomingCallSignal(
            ownChannelDid: ownDid,
            mediaType: CallMediaType.audio,
          ),
        );
        final incoming = await incomingFuture.timeout(
          const Duration(seconds: 1),
        );

        await watchController.close();

        expect(incoming.callId, '!room:example.com');
        await expectLater(
          plugin.cancelledCalls.first.timeout(
            const Duration(milliseconds: 200),
            onTimeout: () => throw TimeoutException('cancelled call'),
          ),
          throwsA(isA<TimeoutException>()),
        );
      },
    );
  });

  group('startCall', () {
    test(
      'disposes previous session and creates a new one when called twice',
      () async {
        final rooms = <FakeLiveKitRoom>[];
        final plugin = _plugin(
          roomFactory: (did) {
            final room = FakeLiveKitRoom();
            rooms.add(room);
            return room;
          },
        );
        plugin.initialize(sdk: _mockSdk());
        addTearDown(() async => plugin.dispose());

        const did = 'did:key:other';

        final session1 = await plugin.startCall(
          otherPartyChannelDid: did,
          mediaType: CallMediaType.video,
        );

        // Give the background joinCall a moment to start and hit the
        // SDK stub (which throws). The service catches it and swallows
        // it because _isDisposed will be true after disposeContainer().
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final session2 = await plugin.startCall(
          otherPartyChannelDid: did,
          mediaType: CallMediaType.video,
        );

        // Two separate rooms = two separate sessions created.
        expect(rooms.length, 2);
        // First room was disconnected — not abandoned.
        expect(
          rooms[0].disconnectCalls,
          greaterThan(0),
          reason: 'first session was cleaned up',
        );
        // A distinct session handle was returned.
        expect(session1, isNot(same(session2)));
      },
    );
  });
}
