import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/handlers/call_signal_handler.dart';
import 'package:meeting_place_matrix/src/pending_call_manager.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'fakes/fake_fallbacks.dart';
import 'mocks/mocks.dart';

const _ownDid = 'did:key:own';
const _callerDid = 'did:key:caller';

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
  late MockMeetingPlaceCoreSDK sdk;
  late MockMeetingPlaceMatrixSDKLogger logger;
  late PendingCallManager pendingCallManager;

  setUpAll(() {
    registerFallbackValue(FakeChannel());
    registerFallbackValue(FakeOutgoingMessage());
  });

  setUp(() {
    sdk = MockMeetingPlaceCoreSDK();
    logger = MockMeetingPlaceMatrixSDKLogger();
    pendingCallManager = PendingCallManager();

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

  CallSignalHandler _handler({
    MockLiveKitCallSession? activeSession,
    List<IncomingAudioVideoCallEvent>? emittedIncoming,
    List<String>? emittedCancelled,
  }) {
    final incoming = emittedIncoming ?? [];
    final cancelled = emittedCancelled ?? [];
    return CallSignalHandler(
      sdk: sdk,
      pendingCallManager: pendingCallManager,
      logger: logger,
      getActiveSession: () => activeSession,
      onIncomingCall: incoming.add,
      onCallCancelled: cancelled.add,
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
        final handler = _handler(emittedIncoming: emitted);

        await handler.onIncomingCallSignal(
          const IncomingCallSignal(ownChannelDid: _ownDid),
        );

        expect(emitted, hasLength(1));
        expect(emitted.first.callId, _callerDid);
        expect(emitted.first.otherPartyChannelDid, _callerDid);
        expect(emitted.first.mediaType, CallMediaType.video);
      },
    );

    test('drops signal when no channel is found', () async {
      when(() => sdk.getChannelByDid(_ownDid)).thenAnswer((_) async => null);

      final emitted = <IncomingAudioVideoCallEvent>[];
      final handler = _handler(emittedIncoming: emitted);

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
        final handler = _handler(emittedIncoming: emitted);

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

      final handler = _handler();

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
      );
      await handlerSecond.onIncomingCallSignal(
        const IncomingCallSignal(ownChannelDid: _ownDid),
      );

      expect(emittedSecond, isEmpty);
    });
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

        final handler = _handler(activeSession: session);

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

        final cancelled = <String>[];
        final handler = _handler(emittedCancelled: cancelled);

        // Register a pending call so removePendingByDid has something to act on
        pendingCallManager.registerIncomingCall(
          callId: _callerDid,
          otherPartyChannelDid: _callerDid,
        );

        await handler.onCallDeclineSignal(
          const CallDeclineSignal(ownChannelDid: _ownDid),
        );

        expect(cancelled, [_callerDid]);
      },
    );

    test('ignores signal when channel cannot be resolved', () async {
      when(
        () => sdk.getChannelByDid(_ownDid),
      ).thenThrow(Exception('network error'));

      final cancelled = <String>[];
      final handler = _handler(emittedCancelled: cancelled);

      await handler.onCallDeclineSignal(
        const CallDeclineSignal(ownChannelDid: _ownDid),
      );

      expect(cancelled, isEmpty);
    });
  });
}
