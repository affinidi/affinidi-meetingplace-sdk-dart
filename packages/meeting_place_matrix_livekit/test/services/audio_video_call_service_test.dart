import 'dart:async';

import 'package:matrix/matrix.dart' show OpenIdCredentials;
import 'package:meeting_place_chat/meeting_place_chat.dart'
    show AudioVideoCallParticipant, AudioVideoCallStatus, CallMediaType;
import 'package:meeting_place_core/meeting_place_core.dart'
    show
        Channel,
        ChannelStatus,
        ChannelTransport,
        ChannelType,
        ContactCard,
        DefaultMeetingPlaceCoreSDKLogger;
import 'package:meeting_place_matrix_livekit/src/meeting_place_livekit_call_plugin_options.dart';
import 'package:meeting_place_matrix_livekit/src/models/sfu_token_response.dart';
import 'package:meeting_place_matrix_livekit/src/services/audio_video_call_service.dart';
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
  required MockMeetingPlaceCoreSDK sdk,
  required FakeLiveKitRoom room,
  MockSfuTokenService? tokenService,
}) => AudioVideoCallService(
  otherPartyChannelDid: _otherPartyDid,
  sdk: sdk,
  options: MeetingPlaceLiveKitCallPluginOptions(
    livekitServiceUrl: Uri.parse('https://livekit.test'),
    livekitSfuUrl: Uri.parse(_sfuUrl),
  ),
  rtcDelegate: MockWebRTCDelegate(),
  logger: DefaultMeetingPlaceCoreSDKLogger(className: 'test'),
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
  });

  late MockMeetingPlaceCoreSDK mockSdk;
  late FakeLiveKitRoom fakeRoom;
  late AudioVideoCallService service;

  setUp(() {
    mockSdk = MockMeetingPlaceCoreSDK();
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
        'leaveVideoCall throws', () async {
      when(
        () => mockSdk.leaveVideoCall(
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
          () => mockSdk.leaveVideoCall(
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

    test('sends call-invite nudge before connecting to LiveKit', () async {
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
        () => mockSdk.livekitRoomName(
          channelDid: any(named: 'channelDid'),
          otherPartyChannelDid: any(named: 'otherPartyChannelDid'),
        ),
      ).thenReturn('test-room');

      when(
        () => mockSdk.getDidManager(any()),
      ).thenAnswer((_) async => mockDidManager);

      when(
        () => mockSdk.resolveMatrixRoomIdForChannel(
          didManager: any(named: 'didManager'),
          channel: any(named: 'channel'),
        ),
      ).thenAnswer((_) async => _matrixRoomId);

      when(
        () => mockSdk.getMatrixOpenIdToken(any()),
      ).thenAnswer((_) async => _stubOpenIdCredentials());

      when(
        () => mockSdk.getMatrixDeviceId(any()),
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
        () => mockSdk.initializeMatrixRTCWithDelegate(
          didManager: any(named: 'didManager'),
          delegate: any(named: 'delegate'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockSdk.activeVideoCallId(
          didManager: any(named: 'didManager'),
          roomId: any(named: 'roomId'),
        ),
      ).thenAnswer((_) async => null);

      when(() => mockSdk.sendMessage(any())).thenAnswer((_) async {
        room.callOrder.add('nudge');
        return null;
      });

      when(
        () => mockSdk.startVideoCall(
          didManager: any(named: 'didManager'),
          roomId: any(named: 'roomId'),
          callId: any(named: 'callId'),
          livekitServiceUrl: any(named: 'livekitServiceUrl'),
          livekitAlias: any(named: 'livekitAlias'),
        ),
      ).thenAnswer((_) async => mockGroupCallSession);

      when(
        () => mockSdk.leaveVideoCall(
          roomId: any(named: 'roomId'),
          callId: any(named: 'callId'),
        ),
      ).thenAnswer((_) async {});

      await svc.joinCall(mediaType: CallMediaType.video);

      expect(room.callOrder, containsAllInOrder(['nudge', 'connect']));
      expect(room.connectCalls, 1);
    });
  });
}
