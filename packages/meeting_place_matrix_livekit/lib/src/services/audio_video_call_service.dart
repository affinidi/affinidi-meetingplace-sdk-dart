import 'dart:async';

import 'package:livekit_client/livekit_client.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart'
    show
        AudioVideoCallErrorCode,
        AudioVideoCallParticipant,
        AudioVideoCallState,
        AudioVideoCallStatus;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/audio_video_call_defaults.dart';
import '../delegates/flutter_matrix_rtc_delegate.dart';
import '../exceptions/meeting_place_livekit_call_exception.dart';
import '../providers/livekit_service_provider.dart';
import '../providers/plugin_core_sdk_provider.dart';
import '../providers/plugin_logger_provider.dart';
import '../providers/plugin_options_provider.dart';
import '../providers/plugin_rtc_delegate_provider.dart';
import '../utils/string.dart';
import 'livekit_service.dart';
import 'sfu_token_service.dart';

part 'audio_video_call_service.g.dart';

/// Orchestrates the full LiveKit call lifecycle for the channel identified
/// by [otherPartyChannelDid] (the other party's permanent channel DID).
///
/// Responsibilities:
/// - Resolves the channel, derives the LiveKit room name, obtains the
///   local user's DidManager, and exchanges for a LiveKit JWT.
/// - Owns [LiveKitService] and [SfuTokenService] for this call.
/// - Publishes [AudioVideoCallState] for the presentation layer to observe.
/// - Disconnects and releases resources on dispose.
///
/// Read by AudioVideoCallScreenController via `ref.listen`.
/// Modelled after ChatSessionService.
@Riverpod(
  dependencies: [pluginCoreSdk, pluginOptions, pluginRtcDelegate, pluginLogger],
)
class AudioVideoCallService extends _$AudioVideoCallService {
  late final MeetingPlaceCoreSDKLogger _logger = ref.read(pluginLoggerProvider);
  late MeetingPlaceCoreSDK _sdk;
  late Duration _e2eeReadyTimeout;
  late SfuTokenService _livekitTokenService;
  late LiveKitService _livekitService;
  late FlutterMatrixRTCDelegate _rtcDelegate;
  bool _isDisposed = false;
  Timer? _e2eeReadyTimer;
  String? _matrixRoomId;
  String? _matrixCallId;
  BaseKeyProvider? _keyProvider;

  @override
  AudioVideoCallState build(String otherPartyChannelDid) {
    _sdk = ref.read(pluginCoreSdkProvider);
    _e2eeReadyTimeout = ref.read(pluginOptionsProvider).e2eeReadyTimeout;
    _rtcDelegate = ref.read(pluginRtcDelegateProvider);
    _livekitTokenService = SfuTokenService(
      serviceUrl: ref.read(pluginOptionsProvider).livekitServiceUrl,
      logger: _logger,
    );
    _livekitService = ref.watch(livekitServiceProvider(otherPartyChannelDid));

    ref.onDispose(() {
      _isDisposed = true;
      _e2eeReadyTimer?.cancel();
      _rtcDelegate.updateKeyProvider(null);
      _keyProvider = null;
      final roomId = _matrixRoomId;
      final callId = _matrixCallId;
      if (roomId != null && callId != null) {
        unawaited(_sdk.leaveVideoCall(roomId: roomId, callId: callId));
      }
      // Ensure the LiveKit room is always released, even if leaveCall() was
      // never called (e.g. screen popped mid-call or app killed).
      unawaited(_livekitService.disconnect());
    });

    return AudioVideoCallState.initial;
  }

  Future<void> joinCall({bool isCallee = false}) async {
    const methodName = 'joinCall';
    if (_isDisposed) return;
    state = state.copyWith(
      status: AudioVideoCallStatus.connecting,
      clearErrorCode: true,
    );

    var errorCode = AudioVideoCallErrorCode.unexpected;
    var succeeded = false;
    try {
      errorCode = AudioVideoCallErrorCode.channelNotFound;
      final channel = await _sdk.getChannelByOtherPartyPermanentDid(
        otherPartyChannelDid,
      );
      if (channel == null) {
        throw MeetingPlaceLiveKitCallOperationException(
          'No channel found for contact DID: $otherPartyChannelDid',
        );
      }

      final ownChannelDid = channel.permanentChannelDid;
      if (ownChannelDid == null) {
        throw MeetingPlaceLiveKitCallOperationException(
          'Channel for contact $otherPartyChannelDid'
          ' has no permanentChannelDid',
        );
      }

      final roomName = channel.isGroup
          ? _sdk.livekitRoomName(channelDid: otherPartyChannelDid)
          : _sdk.livekitRoomName(
              channelDid: ownChannelDid,
              otherPartyChannelDid: otherPartyChannelDid,
            );

      errorCode = AudioVideoCallErrorCode.tokenFetchFailed;
      final didManager = await _sdk.getDidManager(ownChannelDid);
      final matrixRoomId = await _sdk.resolveMatrixRoomIdForChannel(
        didManager: didManager,
        channel: channel,
      );
      final openIdToken = await _sdk.getMatrixOpenIdToken(didManager);
      final deviceId = await _sdk.getMatrixDeviceId(didManager);

      final tokenResponse = await _livekitTokenService.fetchToken(
        roomName: roomName,
        openIdCredentials: openIdToken,
        deviceId: deviceId,
      );

      final sfuUrl =
          ref.read(pluginOptionsProvider).livekitSfuUrl?.toString() ??
          tokenResponse.url;
      if (sfuUrl == null) {
        throw const MeetingPlaceLiveKitCallOperationException(
          'No LiveKit SFU URL available: set livekitSfuUrl in plugin options '
          'or ensure lk-jwt-service returns a URL in the response',
        );
      }

      errorCode = AudioVideoCallErrorCode.connectionFailed;
      await _sdk.initializeMatrixRTCWithDelegate(
        didManager: didManager,
        delegate: _rtcDelegate,
      );

      final keyProvider = await BaseKeyProvider.create(
        sharedKey: AudioVideoCallDefaults.sharedKeyEncryption,
      );
      _keyProvider = keyProvider;
      _rtcDelegate.updateKeyProvider(keyProvider);

      await _livekitService.connect(
        url: sfuUrl,
        token: tokenResponse.token,
        keyProvider: keyProvider,
        onE2EEStateChanged: _onE2EEStateChanged,
        onParticipantDisconnected: _onParticipantDisconnected,
        onParticipantsChanged: _onParticipantsChanged,
      );

      await _enableLocalMedia();

      await _sdk.startVideoCall(
        didManager: didManager,
        roomId: matrixRoomId,
        livekitServiceUrl: sfuUrl,
        livekitAlias: roomName,
      );
      _matrixRoomId = matrixRoomId;
      _matrixCallId = matrixRoomId; // callId defaults to roomId in startCall

      if (!isCallee) {
        // Nudge the callee via the control-plane channel-activity pipeline.
        // This triggers the same FCM push + CP event processing path used for
        // chat messages: the callee's app receives a 'call-invite'
        // ChannelActivity, which the SDK emits on incomingCallSignals, and the
        // plugin converts to an IncomingCallEvent that rings the device.
        errorCode = AudioVideoCallErrorCode.callInviteFailed;
        await _sdk.sendChannelNotification(
          channel.isGroup
              ? GroupChannelNotification(
                  offerLink: channel.offerLink,
                  groupDid: otherPartyChannelDid,
                  type: ChannelActivityType.callInvite,
                )
              : IndividualChannelNotification(
                  recipientDid: otherPartyChannelDid,
                  type: ChannelActivityType.callInvite,
                ),
        );
        _logger.info(
          'Sent call-invite nudge to ${otherPartyChannelDid.topAndTail()}',
          name: methodName,
        );
      }

      if (_isDisposed) return;
      state = state.copyWith(
        status: AudioVideoCallStatus.waitingForKeys,
        participants: _livekitService.participants,
      );
      _e2eeReadyTimer = Timer(_e2eeReadyTimeout, _onE2EETimeout);
      succeeded = true;
    } on MeetingPlaceLiveKitCallOperationException catch (e, stackTrace) {
      if (_isDisposed) return;
      _logger.error(
        'Failed to join call',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      state = state.copyWith(
        status: AudioVideoCallStatus.error,
        errorCode: errorCode,
      );
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _logger.error(
        'Unexpected error joining call',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      state = state.copyWith(
        status: AudioVideoCallStatus.error,
        errorCode: AudioVideoCallErrorCode.unexpected,
      );
    } finally {
      // If the call setup did not complete successfully, stop the LiveKit room
      // immediately. Without this, a Room that threw during connect() keeps its
      // internal reconnect loop running until the provider is disposed.
      if (!succeeded) unawaited(_livekitService.disconnect());
    }
  }

  /// Leaves the LiveKit room gracefully.
  Future<void> leaveCall() async {
    if (_isDisposed) return;
    state = state.copyWith(status: AudioVideoCallStatus.disconnecting);
    _e2eeReadyTimer?.cancel();

    // Null out before awaiting so onDispose does not repeat the cleanup if
    // the screen is dismissed while this method is in flight.
    final roomId = _matrixRoomId;
    final callId = _matrixCallId;
    _matrixRoomId = null;
    _matrixCallId = null;

    try {
      if (roomId != null && callId != null) {
        await _sdk.leaveVideoCall(roomId: roomId, callId: callId);
      }
      await _livekitService.disconnect();
    } finally {
      if (!_isDisposed) {
        state = state.copyWith(
          status: AudioVideoCallStatus.disconnected,
          participants: <AudioVideoCallParticipant>[],
        );
      }
    }
  }

  /// Enables or disables the local microphone.
  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (_isDisposed) return;
    await _livekitService.setMicrophoneEnabled(enabled);
    state = state.copyWith(participants: _livekitService.participants);
  }

  /// Enables or disables the local camera.
  Future<void> setCameraEnabled(bool enabled) async {
    if (_isDisposed) return;
    await _livekitService.setCameraEnabled(enabled);
    state = state.copyWith(participants: _livekitService.participants);
  }

  /// Routes audio through the loudspeaker ([enabled] = true) or earpiece
  /// ([enabled] = false).
  ///
  /// The presentation layer determines the initial value based on contact type
  /// and call mode, then calls this method on each user toggle. No-op when
  /// disposed.
  Future<void> setSpeakerphoneEnabled(bool enabled) async {
    if (_isDisposed) return;
    await _livekitService.setSpeakerphoneEnabled(enabled);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Publishes the local microphone and camera tracks after connecting.
  ///
  /// Camera failures are logged but not fatal: device emulators and machines
  /// without a camera throw here, yet the call must still proceed audio-only.
  Future<void> _enableLocalMedia() async {
    const methodName = '_enableLocalMedia';
    try {
      await _livekitService.setMicrophoneEnabled(true);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to enable microphone',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
    }
    try {
      await _livekitService.setCameraEnabled(true);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to enable camera',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
    }
  }

  void _onParticipantsChanged() {
    if (_isDisposed) return;
    state = state.copyWith(participants: _livekitService.participants);
  }

  void _onParticipantDisconnected(String identity) {
    if (_isDisposed) return;
    // Ratchet own key so the departed participant cannot decrypt future media.
    final ownIdentity = _livekitService.ownIdentity;
    if (ownIdentity != null) {
      unawaited(_keyProvider?.ratchetKey(ownIdentity, 0));
    }
    state = state.copyWith(participants: _livekitService.participants);
  }

  void _onE2EEStateChanged(String participantIdentity, E2EEState e2eeState) {
    if (_isDisposed) return;
    if (e2eeState == E2EEState.kOk) {
      _e2eeReadyTimer?.cancel();
      if (state.status == AudioVideoCallStatus.waitingForKeys ||
          state.status == AudioVideoCallStatus.connected) {
        state = state.copyWith(
          status: AudioVideoCallStatus.active,
          participants: _livekitService.participants,
        );
      }
    }
  }

  void _onE2EETimeout() {
    if (_isDisposed) return;
    if (state.status == AudioVideoCallStatus.waitingForKeys) {
      // Transition to connected anyway — the call is usable even if E2EE
      // keys for some remote participants haven't arrived yet.
      state = state.copyWith(
        status: AudioVideoCallStatus.connected,
        participants: _livekitService.participants,
      );
    }
  }
}
