import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart'
    show AudioVideoCallParticipant, AudioVideoCallState, AudioVideoCallStatus;
import 'package:meeting_place_core/meeting_place_core.dart'
    show DefaultMeetingPlaceCoreSDKLogger;
import 'package:meeting_place_matrix_livekit/src/delegates/flutter_matrix_rtc_delegate.dart';
import 'package:meeting_place_matrix_livekit/src/meeting_place_livekit_call_plugin_options.dart';
import 'package:meeting_place_matrix_livekit/src/providers/livekit_service_provider.dart';
import 'package:meeting_place_matrix_livekit/src/providers/plugin_core_sdk_provider.dart';
import 'package:meeting_place_matrix_livekit/src/providers/plugin_logger_provider.dart';
import 'package:meeting_place_matrix_livekit/src/providers/plugin_options_provider.dart';
import 'package:meeting_place_matrix_livekit/src/providers/plugin_rtc_delegate_provider.dart';
import 'package:meeting_place_matrix_livekit/src/services/audio_video_call_service.dart';
import 'package:mocktail/mocktail.dart';

import '../fakes/fake_livekit_service.dart';
import '../mocks/mocks.dart';

const _otherPartyDid = 'did:key:other-party';

ProviderContainer _buildContainer({
  required MockMeetingPlaceCoreSDK mockSdk,
  required FakeLiveKitService fakeService,
}) => ProviderContainer(
  overrides: [
    pluginCoreSdkProvider.overrideWith((ref) => mockSdk),
    pluginLoggerProvider.overrideWith(
      (ref) => DefaultMeetingPlaceCoreSDKLogger(className: 'test'),
    ),
    pluginOptionsProvider.overrideWith(
      (ref) => MeetingPlaceLiveKitCallPluginOptions(
        livekitServiceUrl: Uri.parse('https://livekit.test'),
      ),
    ),
    pluginRtcDelegateProvider.overrideWith((ref) => FlutterMatrixRTCDelegate()),
    livekitServiceProvider(_otherPartyDid).overrideWith((ref) => fakeService),
  ],
);

void main() {
  late MockMeetingPlaceCoreSDK mockSdk;
  late FakeLiveKitService fakeService;
  late ProviderContainer container;

  setUp(() {
    mockSdk = MockMeetingPlaceCoreSDK();
    fakeService = FakeLiveKitService();
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
        'LiveKitService disconnect throws', () async {
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
  });
}
