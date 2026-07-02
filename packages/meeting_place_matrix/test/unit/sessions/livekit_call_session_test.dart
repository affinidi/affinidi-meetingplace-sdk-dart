import 'dart:async';

import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../fakes/fake_livekit_service.dart';
import '../mocks/mocks.dart';

class _FakeAudioVideoCallService extends Fake implements AudioVideoCallService {
  final _stateController = StreamController<AudioVideoCallState>.broadcast();

  void emit(AudioVideoCallState s) => _stateController.add(s);

  @override
  Stream<AudioVideoCallState> get stateStream => _stateController.stream;

  @override
  LiveKitRoom get room => FakeLiveKitRoom();

  @override
  Future<void> dispose() => _stateController.close();
}

AudioVideoCallParticipant _self() =>
    const AudioVideoCallParticipant(participantId: 'self', isSelf: true);

AudioVideoCallParticipant _peer(String id) =>
    AudioVideoCallParticipant(participantId: id);

AudioVideoCallService _buildService() {
  final sdk = MockMeetingPlaceMatrixSDK();
  when(() => sdk.matrixService).thenReturn(MockMatrixService());
  return AudioVideoCallService(
    otherPartyChannelDid: 'did:peer:other-party',
    sdk: sdk,
    livekitSfuUrl: null,
    e2eeReadyTimeout: const Duration(seconds: 10),
    outgoingCallTimeout: const Duration(seconds: 60),
    rtcDelegate: MockWebRTCDelegate(),
    logger: DefaultMeetingPlaceMatrixSDKLogger(className: 'test'),
    livekitTokenService: MockSfuTokenService(),
    room: FakeLiveKitRoom(),
  );
}

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

  group('participantEvents', () {
    late _FakeAudioVideoCallService fakeService;
    late LiveKitCallSession fakeSession;

    setUp(() {
      fakeService = _FakeAudioVideoCallService();
      fakeSession = LiveKitCallSession.create(
        service: fakeService,
        otherPartyChannelDid: otherPartyChannelDid,
        logger: MockMeetingPlaceMatrixSDKLogger(),
      );
    });

    tearDown(() async => fakeSession.dispose());

    test(
      'emits joined event when a new peer appears in participants',
      () async {
        final events = <CallParticipantEvent>[];
        fakeSession.participantEvents.listen(events.add);

        fakeService.emit(
          AudioVideoCallState(
            status: AudioVideoCallStatus.active,
            participants: [_self(), _peer('p1')],
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.single.type, CallParticipantEventType.joined);
        expect(events.single.participant.participantId, 'p1');
      },
    );

    test('emits left event when a peer disappears from participants', () async {
      final events = <CallParticipantEvent>[];
      fakeSession.participantEvents.listen(events.add);

      fakeService.emit(
        AudioVideoCallState(
          status: AudioVideoCallStatus.active,
          participants: [_self(), _peer('p1')],
        ),
      );
      fakeService.emit(
        AudioVideoCallState(
          status: AudioVideoCallStatus.active,
          participants: [_self()],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final leftEvents = events
          .where((e) => e.type == CallParticipantEventType.left)
          .toList();
      expect(leftEvents, hasLength(1));
      expect(leftEvents.single.participant.participantId, 'p1');
    });

    test('does not emit events for self participant changes', () async {
      final events = <CallParticipantEvent>[];
      fakeSession.participantEvents.listen(events.add);

      fakeService.emit(
        AudioVideoCallState(
          status: AudioVideoCallStatus.active,
          participants: [_self()],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });

    test('emits no events after dispose', () async {
      final events = <CallParticipantEvent>[];
      fakeSession.participantEvents.listen(events.add);

      await fakeSession.dispose();

      // After dispose the stream controller is closed; emit may throw or be
      // ignored — either way, no events should reach the listener.
      try {
        fakeService.emit(
          AudioVideoCallState(
            status: AudioVideoCallStatus.active,
            participants: [_self(), _peer('p1')],
          ),
        );
      } catch (_) {}
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });
  });
}
