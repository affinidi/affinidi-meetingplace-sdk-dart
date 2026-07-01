import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:test/test.dart';

import '../fakes/fake_livekit_service.dart';
import '../mocks/mocks.dart';

AudioVideoCallService _buildService() => AudioVideoCallService(
  otherPartyChannelDid: 'did:peer:other-party',
  sdk: MockMeetingPlaceMatrixSDK(),
  livekitSfuUrl: null,
  e2eeReadyTimeout: const Duration(seconds: 10),
  outgoingCallTimeout: const Duration(seconds: 60),
  rtcDelegate: MockWebRTCDelegate(),
  logger: DefaultMeetingPlaceMatrixSDKLogger(className: 'test'),
  livekitTokenService: MockSfuTokenService(),
  room: FakeLiveKitRoom(),
);

void main() {
  const otherPartyChannelDid = 'did:peer:other-party';

  late MockMeetingPlaceMatrixSDKLogger logger;
  late LiveKitCallSession session;
  late AudioVideoCallService service;

  setUp(() {
    logger = MockMeetingPlaceMatrixSDKLogger();
    service = _buildService();
    session = LiveKitCallSession.create(
      service: service,
      otherPartyChannelDid: otherPartyChannelDid,
      logger: logger,
    );
  });

  tearDown(() async => session.dispose());

  group('plugin-internal accessors', () {
    test('exposes the injected otherPartyChannelDid', () {
      expect(session.otherPartyChannelDid, otherPartyChannelDid);
    });

    test('room getter returns the service room', () {
      expect(session.room, same(service.room));
    });
  });

  group('dispose', () {
    test('disposes without throwing', () async {
      await expectLater(session.dispose(), completes);
    });
  });

  group('state stream', () {
    test('replays the latest state to a late subscriber on listen', () async {
      final received = await session.state.first;

      expect(received, same(AudioVideoCallState.initial));
    });

    test('replays to every independent subscriber', () async {
      final first = await session.state.first;
      final second = await session.state.first;

      expect(first, same(AudioVideoCallState.initial));
      expect(second, same(AudioVideoCallState.initial));
    });
  });
}
