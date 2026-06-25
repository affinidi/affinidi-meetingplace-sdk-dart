import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart' show OpenIdCredentials;
import 'package:meeting_place_chat/meeting_place_chat.dart'
    show
        AudioVideoCallParticipant,
        AudioVideoCallState,
        AudioVideoCallStatus,
        CallMediaType;
import 'package:meeting_place_core/meeting_place_core.dart'
    show
        Channel,
        ChannelStatus,
        ChannelTransport,
        ChannelType,
        ContactCard,
        DefaultMeetingPlaceCoreSDKLogger;
import 'package:meeting_place_matrix_livekit/src/delegates/flutter_matrix_rtc_delegate.dart';
import 'package:meeting_place_matrix_livekit/src/meeting_place_livekit_call_plugin_options.dart';
import 'package:meeting_place_matrix_livekit/src/models/sfu_token_response.dart';
import 'package:meeting_place_matrix_livekit/src/providers/livekit_key_provider_factory_provider.dart';
import 'package:meeting_place_matrix_livekit/src/providers/livekit_service_provider.dart';
import 'package:meeting_place_matrix_livekit/src/providers/plugin_core_sdk_provider.dart';
import 'package:meeting_place_matrix_livekit/src/providers/plugin_logger_provider.dart';
import 'package:meeting_place_matrix_livekit/src/providers/plugin_options_provider.dart';
import 'package:meeting_place_matrix_livekit/src/providers/plugin_rtc_delegate_provider.dart';
import 'package:meeting_place_matrix_livekit/src/providers/sfu_token_service_provider.dart';
import 'package:meeting_place_matrix_livekit/src/services/audio_video_call_service.dart';
import 'package:mocktail/mocktail.dart';

import '../fakes/fake_base_key_provider.dart';
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

ProviderContainer _buildContainer({
  required MockMeetingPlaceCoreSDK mockSdk,
  required FakeLivekitService fakeService,
  MockSfuTokenService? mockTokenService,
  bool useFakeKeyProvider = false,
}) => ProviderContainer(
  overrides: [
    pluginCoreSdkProvider.overrideWith((ref) => mockSdk),
    pluginLoggerProvider.overrideWith(
      (ref) => DefaultMeetingPlaceCoreSDKLogger(className: 'test'),
    ),
    pluginOptionsProvider.overrideWith(
      (ref) => MeetingPlaceLiveKitCallPluginOptions(
        livekitServiceUrl: Uri.parse('https://livekit.test'),
        livekitSfuUrl: Uri.parse(_sfuUrl),
      ),
    ),
    pluginRtcDelegateProvider.overrideWith((ref) => FlutterMatrixRTCDelegate()),
    livekitServiceProvider(_otherPartyDid).overrideWith((ref) => fakeService),
    if (mockTokenService != null)
      sfuTokenServiceProvider.overrideWith((ref) => mockTokenService),
    if (useFakeKeyProvider)
      livekitKeyProviderFactoryProvider.overrideWith(
        (ref) =>
            ({required bool sharedKey}) async => FakeBaseKeyProvider(),
      ),
  ],
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
  late FakeLivekitService fakeService;
  late ProviderContainer container;

  setUp(() {
    mockSdk = MockMeetingPlaceCoreSDK();
    fakeService = FakeLivekitService();
    container = _buildContainer(mockSdk: mockSdk, fakeService: fakeService);
    // Hold a listener so the auto-dispose provider stays alive for the test.
    container.listen(
      audioVideoCallServiceProvider(_otherPartyDid),
      (previous, next) {},
    );
  });

  tearDown(() => container.dispose());

  group('initial state', () {
    test('is AudioVideoCallState.initial', () {
      expect(
        container.read(audioVideoCallServiceProvider(_otherPartyDid)),
        AudioVideoCallState.initial,
      );
    });
  });

  group('leaveCall', () {
    test('transitions to disconnected when not previously joined', () async {
      await container
          .read(audioVideoCallServiceProvider(_otherPartyDid).notifier)
          .leaveCall();

      expect(
        container.read(audioVideoCallServiceProvider(_otherPartyDid)).status,
        AudioVideoCallStatus.disconnected,
      );
      expect(fakeService.disconnectCalls, 1);
    });

    test('completes successfully and transitions to disconnected even when SDK '
        'leaveVideoCall throws', () async {
      when(
        () => mockSdk.leaveVideoCall(
          roomId: any(named: 'roomId'),
          callId: any(named: 'callId'),
        ),
      ).thenThrow(Exception('Teardown failed'));

      // Should not throw, should complete normally.
      await container
          .read(audioVideoCallServiceProvider(_otherPartyDid).notifier)
          .leaveCall();

      // State must be disconnected despite the SDK exception.
      expect(
        container.read(audioVideoCallServiceProvider(_otherPartyDid)).status,
        AudioVideoCallStatus.disconnected,
      );
      // LiveKit must still be disconnected.
      expect(fakeService.disconnectCalls, 1);
    });

    test('completes successfully and transitions to disconnected even when '
        'LivekitService disconnect throws', () async {
      final service = container.read(
        audioVideoCallServiceProvider(_otherPartyDid).notifier,
      );
      fakeService.disconnectThrows = TimeoutException(
        'Room disconnect timeout',
      );

      // Should not throw, should complete normally.
      await service.leaveCall();

      // State must be disconnected despite the disconnect exception.
      expect(
        container.read(audioVideoCallServiceProvider(_otherPartyDid)).status,
        AudioVideoCallStatus.disconnected,
      );
      // disconnect was called and threw.
      expect(fakeService.disconnectCalls, 1);

      // Clear exception before teardown to avoid onDispose errors.
      fakeService.disconnectThrows = null;
    });

    test(
      'completes successfully when both SDK and LiveKit teardown throw',
      () async {
        final service = container.read(
          audioVideoCallServiceProvider(_otherPartyDid).notifier,
        );
        when(
          () => mockSdk.leaveVideoCall(
            roomId: any(named: 'roomId'),
            callId: any(named: 'callId'),
          ),
        ).thenThrow(Exception('SDK error'));

        fakeService.disconnectThrows = Exception('LiveKit error');

        // Should not throw despite both throwing.
        await service.leaveCall();

        expect(
          container.read(audioVideoCallServiceProvider(_otherPartyDid)).status,
          AudioVideoCallStatus.disconnected,
        );

        // Clear exception before teardown to avoid onDispose errors.
        fakeService.disconnectThrows = null;
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
      fakeService.fakeParticipants = [participant];

      await container
          .read(audioVideoCallServiceProvider(_otherPartyDid).notifier)
          .setMicrophoneEnabled(true);

      expect(fakeService.micCalls, [true]);
      expect(
        container
            .read(audioVideoCallServiceProvider(_otherPartyDid))
            .participants,
        [participant],
      );
    });
  });

  group('setCameraEnabled', () {
    test('forwards to the live service and refreshes participants', () async {
      fakeService.fakeParticipants = [];

      await container
          .read(audioVideoCallServiceProvider(_otherPartyDid).notifier)
          .setCameraEnabled(false);

      expect(fakeService.cameraCalls, [false]);
    });
  });

  group('setSpeakerphoneEnabled', () {
    test('forwards to the live service', () async {
      await container
          .read(audioVideoCallServiceProvider(_otherPartyDid).notifier)
          .setSpeakerphoneEnabled(true);

      expect(fakeService.speakerCalls, [true]);
    });
  });

  group('switchCamera', () {
    test('forwards to the live service', () async {
      await container
          .read(audioVideoCallServiceProvider(_otherPartyDid).notifier)
          .switchCamera();

      expect(fakeService.switchCameraCalls, 1);
    });
  });

  group('joinCall', () {
    test('sets status to error when no channel is found', () async {
      when(
        () => mockSdk.getChannelByOtherPartyPermanentDid(any()),
      ).thenAnswer((_) async => null);

      await container
          .read(audioVideoCallServiceProvider(_otherPartyDid).notifier)
          .joinCall();

      expect(
        container.read(audioVideoCallServiceProvider(_otherPartyDid)).status,
        AudioVideoCallStatus.error,
      );
      // LiveKit room must be released even when join fails.
      expect(fakeService.disconnectCalls, 1);
    });

    test('sends call-invite nudge before connecting to LiveKit', () async {
      final mockTokenService = MockSfuTokenService();
      final mockDidManager = MockDidManager();
      final mockGroupCallSession = MockGroupCallSession();

      // Wire a container with the token service override.
      final c = _buildContainer(
        mockSdk: mockSdk,
        fakeService: fakeService,
        mockTokenService: mockTokenService,
        useFakeKeyProvider: true,
      );
      c.listen(audioVideoCallServiceProvider(_otherPartyDid), (_, _) {});
      addTearDown(c.dispose);

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

      // Record that the nudge was sent, in call-order.
      when(() => mockSdk.sendMessage(any())).thenAnswer((_) async {
        fakeService.callOrder.add('nudge');
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

      await c
          .read(audioVideoCallServiceProvider(_otherPartyDid).notifier)
          .joinCall(mediaType: CallMediaType.video);

      // Nudge must have fired before LiveKit connect.
      expect(fakeService.callOrder, containsAllInOrder(['nudge', 'connect']));
      expect(fakeService.connectCalls, 1);
    });
  });
}
