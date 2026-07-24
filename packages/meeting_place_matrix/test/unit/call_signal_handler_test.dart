import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/handlers/call_signal_handler.dart';
import 'package:meeting_place_matrix/src/managers/pending_call_manager.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'fakes/fake_fallbacks.dart';
import 'mocks/mocks.dart';

const _ownDid = 'did:key:own';
const _callerDid = 'did:key:caller';
const _roomId = '!room:example.com';
const _transportCallId = '!room:example.com@12345';

Channel _channel({String? otherPartyDid = _callerDid}) => Channel(
  offerLink: 'offer-link',
  publishOfferDid: 'did:key:publishOffer',
  mediatorDid: 'did:key:mediator',
  status: ChannelStatus.inaugurated,
  contactCard: ContactCard(
    did: 'did:key:contact',
    type: 'individual',
    contactInfo: const {},
  ),
  type: ChannelType.individual,
  isConnectionInitiator: false,
  permanentChannelDid: _ownDid,
  otherPartyPermanentChannelDid: otherPartyDid,
);

void main() {
  late MockMeetingPlaceMatrixSDK sdk;
  late MockMatrixService matrixService;
  late MockDidManager didManager;
  late MockMeetingPlaceMatrixSDKLogger logger;
  late PendingCallManager pendingCallManager;

  setUpAll(() {
    registerFallbackValue(FakeChannel());
    registerFallbackValue(FakeOutgoingMessage());
    registerFallbackValue(
      const IndividualChannelNotification(recipientDid: '', type: ''),
    );
  });

  setUp(() {
    sdk = MockMeetingPlaceMatrixSDK();
    matrixService = MockMatrixService();
    didManager = MockDidManager();
    logger = MockMeetingPlaceMatrixSDKLogger();
    pendingCallManager = PendingCallManager();

    when(() => sdk.matrixService).thenReturn(matrixService);
    when(() => sdk.getDidManager(any())).thenAnswer((_) async => didManager);
    when(
      () => matrixService.resolveRoomIdForChannel(
        didManager: didManager,
        channel: any(named: 'channel'),
      ),
    ).thenAnswer((_) async => _roomId);
    when(
      () => matrixService.activeCallId(didManager: didManager, roomId: _roomId),
    ).thenAnswer((_) async => _transportCallId);

    when(() => logger.info(any(), name: any(named: 'name'))).thenReturn(null);
    when(
      () => logger.warning(any(), name: any(named: 'name')),
    ).thenReturn(null);
    when(
      () => logger.error(
        any(),
        name: any(named: 'name'),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).thenReturn(null);
  });

  CallSignalHandler callSignalHandler({
    MockLiveKitCallSession? activeSession,
    List<IncomingAudioVideoCallEvent>? emittedIncoming,
    List<IncomingAudioVideoCallEvent>? emittedCancelled,
    List<IncomingAudioVideoCallEvent>? emittedPeerRestarted,
  }) {
    final incoming = emittedIncoming ?? [];
    final cancelled = emittedCancelled ?? [];
    final peerRestarted = emittedPeerRestarted ?? [];
    return CallSignalHandler(
      sdk: sdk,
      pendingCallManager: pendingCallManager,
      logger: logger,
      getActiveSession: () => activeSession,
      onIncomingCall: incoming.add,
      onCallCancelled: cancelled.add,
      onPeerRestartedCall: peerRestarted.add,
    );
  }

  group('onIncomingCallSignal', () {
    test(
      'emits IncomingAudioVideoCallEvent with caller DID on success',
      () async {
        when(
          () => sdk.getChannelByDid(_ownDid),
        ).thenAnswer((_) async => _channel());

        final emitted = <IncomingAudioVideoCallEvent>[];
        final handler = callSignalHandler(emittedIncoming: emitted);

        await handler.onIncomingCallSignal(
          const IncomingCallSignal(ownChannelDid: _ownDid),
        );

        expect(emitted, hasLength(1));
        expect(emitted.first.callId, _transportCallId);
        expect(emitted.first.callerPermanentChannelDid, _callerDid);
        expect(emitted.first.otherPartyPermanentChannelDid, _callerDid);
        expect(emitted.first.mediaType, CallMediaType.video);
      },
    );

    test('drops signal when no channel is found', () async {
      when(() => sdk.getChannelByDid(_ownDid)).thenAnswer((_) async => null);

      final emitted = <IncomingAudioVideoCallEvent>[];
      final handler = callSignalHandler(emittedIncoming: emitted);

      await handler.onIncomingCallSignal(
        const IncomingCallSignal(ownChannelDid: _ownDid),
      );

      expect(emitted, isEmpty);
    });

    test(
      'drops signal when channel has no otherPartyPermanentChannelDid',
      () async {
        when(
          () => sdk.getChannelByDid(_ownDid),
        ).thenAnswer((_) async => _channel(otherPartyDid: null));

        final emitted = <IncomingAudioVideoCallEvent>[];
        final handler = callSignalHandler(emittedIncoming: emitted);

        await handler.onIncomingCallSignal(
          const IncomingCallSignal(ownChannelDid: _ownDid),
        );

        expect(emitted, isEmpty);
      },
    );

    test('auto-rejects when already in a call', () async {
      when(
        () => sdk.getChannelByDid(_ownDid),
      ).thenAnswer((_) async => _channel());

      final handler = callSignalHandler();

      // First call registers successfully.
      await handler.onIncomingCallSignal(
        const IncomingCallSignal(ownChannelDid: _ownDid),
      );

      // Second call is auto-rejected by the pending call manager.
      final emittedSecond = <IncomingAudioVideoCallEvent>[];
      final handlerSecond = CallSignalHandler(
        sdk: sdk,
        pendingCallManager: pendingCallManager, // same manager = same state
        logger: logger,
        getActiveSession: () => null,
        onIncomingCall: emittedSecond.add,
        onCallCancelled: (_) {},
        onPeerRestartedCall: (_) {},
      );
      await handlerSecond.onIncomingCallSignal(
        const IncomingCallSignal(ownChannelDid: _ownDid),
      );

      expect(emittedSecond, isEmpty);
    });

    test('busy auto-reject surfaces on the cancelled-call channel', () async {
      // A call from a different caller arrives while already in a call. The
      // pending manager rejects it (busy), and the rejection is surfaced on the
      // cancelled-call channel so the app can record a missed call.
      const otherOwnDid = 'did:key:own-2';
      const otherCallerDid = 'did:key:caller-2';
      when(
        () => sdk.getChannelByDid(_ownDid),
      ).thenAnswer((_) async => _channel());
      when(
        () => sdk.getChannelByDid(otherOwnDid),
      ).thenAnswer((_) async => _channel(otherPartyDid: otherCallerDid));
      when(() => sdk.notifyChannel(any())).thenAnswer((_) async {});

      final handler = callSignalHandler();
      await handler.onIncomingCallSignal(
        const IncomingCallSignal(ownChannelDid: _ownDid),
      );

      final cancelled = <IncomingAudioVideoCallEvent>[];
      final handlerSecond = CallSignalHandler(
        sdk: sdk,
        pendingCallManager: pendingCallManager, // same manager = same state
        logger: logger,
        getActiveSession: () => null,
        onIncomingCall: (_) {},
        onCallCancelled: cancelled.add,
        onPeerRestartedCall: (_) {},
      );
      await handlerSecond.onIncomingCallSignal(
        const IncomingCallSignal(ownChannelDid: otherOwnDid),
      );

      expect(cancelled, hasLength(1));
      expect(cancelled.single.callId, _transportCallId);
      expect(cancelled.single.callerPermanentChannelDid, otherCallerDid);
    });

    test(
      '''routes re-invite from current peer to onPeerRestartedCall, not auto-decline''',
      () async {
        when(
          () => sdk.getChannelByDid(_ownDid),
        ).thenAnswer((_) async => _channel());

        // Mark an outbound call so isInCallWith returns true for _callerDid.
        pendingCallManager.markOutboundCall(_callerDid);

        final emittedIncoming = <IncomingAudioVideoCallEvent>[];
        final emittedRestarted = <IncomingAudioVideoCallEvent>[];
        final handler = callSignalHandler(
          emittedIncoming: emittedIncoming,
          emittedPeerRestarted: emittedRestarted,
        );

        await handler.onIncomingCallSignal(
          const IncomingCallSignal(ownChannelDid: _ownDid),
        );

        expect(emittedIncoming, isEmpty);
        expect(emittedRestarted, hasLength(1));
        expect(
          emittedRestarted.first.otherPartyPermanentChannelDid,
          _callerDid,
        );
      },
    );

    test(
      '''simultaneous call keeps our outgoing call when our DID is higher''',
      () async {
        const lowerPeerDid = 'did:key:aaa';
        when(
          () => sdk.getChannelByDid(_ownDid),
        ).thenAnswer((_) async => _channel(otherPartyDid: lowerPeerDid));

        pendingCallManager.markOutboundCall(lowerPeerDid);

        final session = MockLiveKitCallSession();
        when(() => session.isDiallingTo(lowerPeerDid)).thenReturn(true);

        final emittedIncoming = <IncomingAudioVideoCallEvent>[];
        final emittedRestarted = <IncomingAudioVideoCallEvent>[];
        final handler = callSignalHandler(
          activeSession: session,
          emittedIncoming: emittedIncoming,
          emittedPeerRestarted: emittedRestarted,
        );

        await handler.onIncomingCallSignal(
          const IncomingCallSignal(ownChannelDid: _ownDid),
        );

        expect(emittedIncoming, isEmpty);
        expect(emittedRestarted, isEmpty);
      },
    );

    test(
      '''simultaneous call tears down and rejoins when our DID is lower''',
      () async {
        const higherPeerDid = 'did:key:zzz';
        when(
          () => sdk.getChannelByDid(_ownDid),
        ).thenAnswer((_) async => _channel(otherPartyDid: higherPeerDid));

        pendingCallManager.markOutboundCall(higherPeerDid);

        final session = MockLiveKitCallSession();
        when(() => session.isDiallingTo(higherPeerDid)).thenReturn(true);

        final emittedRestarted = <IncomingAudioVideoCallEvent>[];
        final handler = callSignalHandler(
          activeSession: session,
          emittedPeerRestarted: emittedRestarted,
        );

        await handler.onIncomingCallSignal(
          const IncomingCallSignal(ownChannelDid: _ownDid),
        );

        expect(emittedRestarted, hasLength(1));
      },
    );
  });

  group('onCallDeclineSignal', () {
    test(
      'notifies active session when callee declines an outgoing call',
      () async {
        when(
          () => sdk.getChannelByDid(_ownDid),
        ).thenAnswer((_) async => _channel());

        final session = MockLiveKitCallSession();
        when(() => session.otherPartyChannelDid).thenReturn(_callerDid);
        when(session.notifyDeclined).thenReturn(null);

        final handler = callSignalHandler(activeSession: session);

        await handler.onCallDeclineSignal(
          const CallDeclineSignal(ownChannelDid: _ownDid),
        );

        verify(session.notifyDeclined).called(1);
      },
    );

    test(
      'fires onCallCancelled when no active session matches caller DID',
      () async {
        when(
          () => sdk.getChannelByDid(_ownDid),
        ).thenAnswer((_) async => _channel());

        final cancelled = <IncomingAudioVideoCallEvent>[];
        final handler = callSignalHandler(emittedCancelled: cancelled);

        // Register a pending call so removePendingByDid has something to act on
        pendingCallManager.registerIncomingCall(
          callId: _callerDid,
          otherPartyChannelDid: _callerDid,
          mediaType: CallMediaType.audio,
        );

        await handler.onCallDeclineSignal(
          const CallDeclineSignal(ownChannelDid: _ownDid),
        );

        expect(cancelled, hasLength(1));
        expect(cancelled.single.callId, _callerDid);
        expect(cancelled.single.callerPermanentChannelDid, _callerDid);
        expect(cancelled.single.mediaType, CallMediaType.audio);
      },
    );

    test(
      'uses caller DID from the decline signal for group cancel events',
      () async {
        const groupDid = 'did:key:group';
        when(
          () => sdk.getChannelByDid(groupDid),
        ).thenAnswer((_) async => _channel());

        final cancelled = <IncomingAudioVideoCallEvent>[];
        final handler = callSignalHandler(emittedCancelled: cancelled);

        pendingCallManager.registerIncomingCall(
          callId: 'group-call-id',
          otherPartyChannelDid: _callerDid,
          mediaType: CallMediaType.audio,
        );

        await handler.onCallDeclineSignal(
          const CallDeclineSignal(
            ownChannelDid: groupDid,
            otherPartyPermanentChannelDid: _callerDid,
          ),
        );

        expect(cancelled, hasLength(1));
        expect(cancelled.single.callId, 'group-call-id');
        expect(cancelled.single.callerPermanentChannelDid, _callerDid);
        expect(cancelled.single.otherPartyPermanentChannelDid, groupDid);
      },
    );

    test('ignores signal when channel cannot be resolved', () async {
      when(
        () => sdk.getChannelByDid(_ownDid),
      ).thenThrow(Exception('network error'));

      final cancelled = <IncomingAudioVideoCallEvent>[];
      final handler = callSignalHandler(emittedCancelled: cancelled);

      await handler.onCallDeclineSignal(
        const CallDeclineSignal(ownChannelDid: _ownDid),
      );

      expect(cancelled, isEmpty);
    });

    test(
      'sets otherPartyPermanentChannelDid to recipient (signal.ownChannelDid), '
      'not caller',
      () async {
        const recipientDid = 'did:key:recipient';
        when(
          () => sdk.getChannelByDid(recipientDid),
        ).thenAnswer((_) async => _channel(otherPartyDid: _callerDid));

        final cancelled = <IncomingAudioVideoCallEvent>[];
        final handler = callSignalHandler(emittedCancelled: cancelled);

        pendingCallManager.registerIncomingCall(
          callId: _callerDid,
          otherPartyChannelDid: _callerDid,
          mediaType: CallMediaType.audio,
        );

        await handler.onCallDeclineSignal(
          const CallDeclineSignal(ownChannelDid: recipientDid),
        );

        expect(cancelled, hasLength(1));
        expect(
          cancelled.single.otherPartyPermanentChannelDid,
          recipientDid,
          reason:
              'otherPartyPermanentChannelDid must be the recipient '
              '(signal.ownChannelDid), not the caller',
        );
        expect(
          cancelled.single.callerPermanentChannelDid,
          _callerDid,
          reason: 'callerPermanentChannelDid must be the caller',
        );
        expect(cancelled.single.mediaType, CallMediaType.audio);
      },
    );

    test(
      'drops a buffered invite that arrives after a pre-emptive decline',
      () async {
        when(
          () => sdk.getChannelByDid(_ownDid),
        ).thenAnswer((_) async => _channel());

        final incoming = <IncomingAudioVideoCallEvent>[];
        final cancelled = <IncomingAudioVideoCallEvent>[];
        final handler = callSignalHandler(
          emittedIncoming: incoming,
          emittedCancelled: cancelled,
        );

        await handler.onCallDeclineSignal(
          const CallDeclineSignal(
            ownChannelDid: _ownDid,
            otherPartyPermanentChannelDid: _callerDid,
          ),
        );

        await handler.onIncomingCallSignal(
          const IncomingCallSignal(ownChannelDid: _ownDid),
        );

        expect(cancelled, hasLength(1));
        expect(incoming, isEmpty);
      },
    );
  });

  group('_resolveIncomingCallId roomId fallback', () {
    test('returns transport callId when activeCallId is available', () async {
      when(
        () => sdk.getChannelByDid(_ownDid),
      ).thenAnswer((_) async => _channel());

      final emitted = <IncomingAudioVideoCallEvent>[];
      final handler = callSignalHandler(emittedIncoming: emitted);

      await handler.onIncomingCallSignal(
        const IncomingCallSignal(ownChannelDid: _ownDid),
      );

      expect(emitted.single.callId, _transportCallId);
    });

    test(
      'falls back to roomId when transport callId not yet visible',
      () async {
        when(
          () => sdk.getChannelByDid(_ownDid),
        ).thenAnswer((_) async => _channel());

        // Mock activeCallId to return null (transport not visible yet)
        when(
          () => matrixService.activeCallId(
            didManager: didManager,
            roomId: _roomId,
          ),
        ).thenAnswer((_) async => null);

        final emitted = <IncomingAudioVideoCallEvent>[];
        final handler = callSignalHandler(emittedIncoming: emitted);

        await handler.onIncomingCallSignal(
          const IncomingCallSignal(ownChannelDid: _ownDid),
        );

        expect(
          emitted.single.callId,
          _roomId,
          reason:
              'when transport callId is not yet visible, fall back to roomId',
        );
      },
    );

    test(
      'falls back to caller DID when call identifier resolution throws',
      () async {
        when(
          () => sdk.getChannelByDid(_ownDid),
        ).thenAnswer((_) async => _channel());
        when(
          () => matrixService.resolveRoomIdForChannel(
            didManager: didManager,
            channel: any(named: 'channel'),
          ),
        ).thenThrow(Exception('room lookup failed'));

        final emitted = <IncomingAudioVideoCallEvent>[];
        final handler = callSignalHandler(emittedIncoming: emitted);

        await handler.onIncomingCallSignal(
          const IncomingCallSignal(ownChannelDid: _ownDid),
        );

        expect(emitted, hasLength(1));
        expect(
          emitted.single.callId,
          _callerDid,
          reason: 'when room resolution fails, fall back to caller DID',
        );
      },
    );
  });
}
