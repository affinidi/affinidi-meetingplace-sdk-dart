import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:meeting_place_core/meeting_place_core.dart'
    show
        Channel,
        ChannelStatus,
        ChannelTransport,
        ChannelType,
        ContactCard,
        IndividualChannelNotification;
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/call/call_channel_activity_type.dart';
import 'package:meeting_place_matrix/src/models/sfu_token_response.dart';
import 'package:meeting_place_matrix/src/services/audio_video_call_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../fakes/fake_fallbacks.dart';
import '../fakes/fake_livekit_service.dart';
import '../mocks/mocks.dart';

const _otherPartyDid = 'did:key:other-party';
const _ownDid = 'did:key:own';
const _matrixRoomId = '!room:matrix.test';
const _sfuToken = 'livekit-jwt';
const _sfuUrl = 'wss://livekit.test';

Channel _stubChannel() => Channel(
  offerLink: 'offer://test',
  publishOfferDid: _ownDid,
  mediatorDid: 'did:key:mediator',
  status: ChannelStatus.inaugurated,
  contactCard: ContactCard(
    did: _ownDid,
    type: 'individual',
    contactInfo: {'name': 'Test User'},
  ),
  type: ChannelType.individual,
  transport: ChannelTransport.matrix,
  isConnectionInitiator: true,
  permanentChannelDid: _ownDid,
  otherPartyPermanentChannelDid: _otherPartyDid,
);

OpenIdCredentials _stubOpenIdCredentials() => OpenIdCredentials(
  accessToken: 'matrix-openid-token',
  expiresIn: 3600,
  matrixServerName: 'matrix.test',
  tokenType: 'Bearer',
);

AudioVideoCallService _buildService({
  required MockMeetingPlaceMatrixSDK sdk,
  required FakeLiveKitRoom room,
  MockSfuTokenService? tokenService,
}) => AudioVideoCallService(
  otherPartyChannelDid: _otherPartyDid,
  sdk: sdk,
  livekitSfuUrl: Uri.parse(_sfuUrl),
  sfuAllowedHosts: const [],
  e2eeReadyTimeout: const Duration(seconds: 10),
  outgoingCallTimeout: const Duration(seconds: 60),
  rtcDelegate: MockWebRTCDelegate(),
  logger: DefaultMeetingPlaceMatrixSDKLogger(className: 'test'),
  livekitTokenService: tokenService ?? MockSfuTokenService(),
  room: room,
);

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDidManager());
    registerFallbackValue(FakeChannel());
    registerFallbackValue(FakeOutgoingMessage());
    registerFallbackValue(FakeOpenIdCredentials());
    registerFallbackValue(FakeWebRTCDelegate());
    registerFallbackValue(
      const IndividualChannelNotification(
        recipientDid: 'did:key:fallback',
        type: CallChannelActivityType.callDecline,
      ),
    );
  });

  late MockMeetingPlaceMatrixSDK mockSdk;
  late MockMatrixService mockMatrixService;
  late FakeLiveKitRoom fakeRoom;
  late AudioVideoCallService service;

  setUp(() {
    mockSdk = MockMeetingPlaceMatrixSDK();
    mockMatrixService = MockMatrixService();
    when(() => mockSdk.matrixService).thenReturn(mockMatrixService);
    fakeRoom = FakeLiveKitRoom();
    service = _buildService(sdk: mockSdk, room: fakeRoom);
  });

  tearDown(() async => service.dispose());

  group('initial state', () {
    test('status is initial', () {
      expect(service.state.status, AudioVideoCallStatus.idle);
    });
  });

  group('leaveCall', () {
    test('transitions to disconnected when not previously joined', () async {
      await service.leaveCall();

      expect(service.state.status, AudioVideoCallStatus.disconnected);
      expect(fakeRoom.disconnectCalls, 1);
    });

    test('completes successfully and transitions to disconnected even when SDK '
        'leaveCall throws', () async {
      when(
        () => mockMatrixService.leaveCall(
          roomId: any(named: 'roomId'),
          callId: any(named: 'callId'),
        ),
      ).thenThrow(Exception('Teardown failed'));

      await service.leaveCall();

      expect(service.state.status, AudioVideoCallStatus.disconnected);
      expect(fakeRoom.disconnectCalls, 1);
    });

    test('completes successfully and transitions to disconnected even when '
        'LivekitService disconnect throws', () async {
      fakeRoom.disconnectThrows = TimeoutException('Room disconnect timeout');

      await service.leaveCall();

      expect(service.state.status, AudioVideoCallStatus.disconnected);
      expect(fakeRoom.disconnectCalls, 1);

      fakeRoom.disconnectThrows = null;
    });

    test(
      'completes successfully when both SDK and LiveKit teardown throw',
      () async {
        when(
          () => mockMatrixService.leaveCall(
            roomId: any(named: 'roomId'),
            callId: any(named: 'callId'),
          ),
        ).thenThrow(Exception('SDK error'));
        fakeRoom.disconnectThrows = Exception('LiveKit error');

        await service.leaveCall();

        expect(service.state.status, AudioVideoCallStatus.disconnected);

        fakeRoom.disconnectThrows = null;
      },
    );
  });

  group('setMicrophoneEnabled', () {
    test('forwards to the live service and refreshes participants', () async {
      const participant = AudioVideoCallParticipant(
        participantId: 'p1',
        isSelf: true,
        hasVideo: false,
        hasAudio: true,
        isSpeaking: false,
      );
      fakeRoom.fakeParticipants = [participant];

      await service.setMicrophoneEnabled(true);

      expect(fakeRoom.micCalls, [true]);
      expect(service.state.participants, [participant]);
    });
  });

  group('setCameraEnabled', () {
    test('forwards to the live service and refreshes participants', () async {
      fakeRoom.fakeParticipants = [];

      await service.setCameraEnabled(false);

      expect(fakeRoom.cameraCalls, [false]);
    });
  });

  group('setSpeakerphoneEnabled', () {
    test('forwards to the live service', () async {
      await service.setSpeakerphoneEnabled(true);

      expect(fakeRoom.speakerCalls, [true]);
    });
  });

  group('switchCamera', () {
    test('forwards to the live service', () async {
      await service.switchCamera();

      expect(fakeRoom.switchCameraCalls, 1);
    });
  });

  group('joinCall', () {
    test('sets status to error when no channel is found', () async {
      when(
        () => mockSdk.getChannelByOtherPartyPermanentDid(any()),
      ).thenAnswer((_) async => null);

      await service.joinCall();

      expect(service.state.status, AudioVideoCallStatus.error);
      expect(fakeRoom.disconnectCalls, 1);
    });

    test('sends call-invite room event after connecting to LiveKit', () async {
      final mockTokenService = MockSfuTokenService();
      final mockDidManager = MockDidManager();
      final mockGroupCallSession = MockGroupCallSession();
      final room = FakeLiveKitRoom();
      final svc = _buildService(
        sdk: mockSdk,
        room: room,
        tokenService: mockTokenService,
      );
      addTearDown(svc.dispose);

      when(
        () => mockSdk.getChannelByOtherPartyPermanentDid(_otherPartyDid),
      ).thenAnswer((_) async => _stubChannel());
      when(
        () => mockSdk.getGroupByOfferLink(any()),
      ).thenAnswer((_) async => null);

      when(
        () => mockSdk.getDidManager(any()),
      ).thenAnswer((_) async => mockDidManager);

      when(
        () => mockMatrixService.resolveRoomIdForChannel(
          didManager: any(named: 'didManager'),
          channel: any(named: 'channel'),
        ),
      ).thenAnswer((_) async => _matrixRoomId);

      when(
        () => mockMatrixService.getOpenIdToken(any()),
      ).thenAnswer((_) async => _stubOpenIdCredentials());

      when(
        () => mockMatrixService.getDeviceId(any()),
      ).thenAnswer((_) async => 'DEVICE1');

      when(
        () => mockTokenService.fetchToken(
          roomName: any(named: 'roomName'),
          openIdCredentials: any(named: 'openIdCredentials'),
          deviceId: any(named: 'deviceId'),
        ),
      ).thenAnswer(
        (_) async => const SfuTokenResponse(token: _sfuToken, url: _sfuUrl),
      );

      when(
        () => mockMatrixService.initializeVoIPWithDelegate(
          didManager: any(named: 'didManager'),
          delegate: any(named: 'delegate'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockMatrixService.activeCallId(
          didManager: any(named: 'didManager'),
          roomId: any(named: 'roomId'),
        ),
      ).thenAnswer((_) async => null);

      when(
        () => mockMatrixService.startCall(
          didManager: any(named: 'didManager'),
          roomId: any(named: 'roomId'),
          callId: any(named: 'callId'),
          livekitServiceUrl: any(named: 'livekitServiceUrl'),
          livekitAlias: any(named: 'livekitAlias'),
        ),
      ).thenAnswer((_) async => mockGroupCallSession);

      when(
        () => mockMatrixService.sendRoomEvent(
          any(),
          any(),
          any(),
          didManager: any(named: 'didManager'),
        ),
      ).thenAnswer((_) async {
        room.callOrder.add('nudge');
        return null;
      });

      when(() => mockSdk.notifyChannel(any())).thenAnswer((_) async {});

      when(
        () => mockMatrixService.leaveCall(
          roomId: any(named: 'roomId'),
          callId: any(named: 'callId'),
        ),
      ).thenAnswer((_) async {});

      await svc.joinCall(mediaType: CallMediaType.video);

      expect(room.callOrder, containsAllInOrder(['connect', 'nudge']));
      expect(room.connectCalls, 1);
    });
  });

  group('notifyDeclined', () {
    test('transitions from outgoingRinging to declined', () async {
      final channelCompleter = Completer<Channel?>();
      when(
        () => mockSdk.getChannelByOtherPartyPermanentDid(any()),
      ).thenAnswer((_) => channelCompleter.future);

      unawaited(service.joinCall());
      await Future<void>.delayed(Duration.zero);

      expect(service.state.status, AudioVideoCallStatus.connecting);

      service.notifyDeclined();

      expect(service.state.status, AudioVideoCallStatus.declined);
    });

    test('is ignored when status is not connecting or outgoingRinging', () {
      expect(service.state.status, AudioVideoCallStatus.idle);

      service.notifyDeclined();

      expect(service.state.status, AudioVideoCallStatus.idle);
    });

    test('is ignored when service is disposed', () async {
      await service.dispose();

      service.notifyDeclined();

      expect(service.state.status, AudioVideoCallStatus.idle);
    });
  });

  group('dispose', () {
    test(
      'disconnects LiveKit room and skips leaveCall when no session prepared',
      () async {
        await service.dispose();

        expect(fakeRoom.disconnectCalls, 1);
        expect(fakeRoom.callOrder, contains('disconnect'));
      },
    );

    test('is idempotent when called multiple times', () async {
      await service.dispose();
      await service.dispose();

      expect(fakeRoom.disconnectCalls, 1);
    });
  });
}
