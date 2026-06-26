import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart'
    show AudioVideoCallSession, AudioVideoCallState;
import 'package:meeting_place_core/meeting_place_core.dart'
    show MeetingPlaceCoreSDKLogger;
import 'package:riverpod/riverpod.dart';

import '../services/audio_video_call_service.dart';
import '../utils/string.dart';

/// Concrete [AudioVideoCallSession] for a LiveKit-backed call.
///
/// Wraps the plugin-scoped [ProviderContainer] and delegates all operations to
/// `AudioVideoCallService`. Created by `MeetingPlaceLiveKitCallPlugin` on
/// `startCall` or `acceptCall` and handed to the caller as the live handle.
///
/// The session is single-use: once [hangUp] is called the container is
/// disposed and the session must be discarded.
class LiveKitCallSession implements AudioVideoCallSession {
  LiveKitCallSession._(
    ProviderContainer container,
    String otherPartyChannelDid,
    MeetingPlaceCoreSDKLogger logger,
  ) : _container = container,
      _otherPartyChannelDid = otherPartyChannelDid,
      _logger = logger {
    // Hold a persistent subscription so the autoDispose provider stays alive
    // for the entire session lifetime, even while joinCall is mid-flight before
    // the caller has subscribed to the state stream.
    _stateController = StreamController<AudioVideoCallState>.broadcast();
    _stateSub = _container.listen(
      audioVideoCallServiceProvider(_otherPartyChannelDid),
      (_, AudioVideoCallState next) {
        _latestState = next;
        if (!_stateController.isClosed) _stateController.add(next);
      },
      fireImmediately: true,
    );
  }

  final ProviderContainer _container;
  final String _otherPartyChannelDid;
  final MeetingPlaceCoreSDKLogger _logger;
  late final StreamController<AudioVideoCallState> _stateController;
  late final ProviderSubscription<AudioVideoCallState> _stateSub;

  // Latest state pushed by the service. Replayed to late subscribers so a
  // transient emission (e.g. the one carrying ownRole) is never missed if
  // the caller subscribes after the service has already moved on.
  AudioVideoCallState _latestState = AudioVideoCallState.initial;

  static const _logKey = 'LiveKitCallSession';

  /// Factory used only by `MeetingPlaceLiveKitCallPlugin`.
  static LiveKitCallSession create({
    required ProviderContainer container,
    required String otherPartyChannelDid,
    required MeetingPlaceCoreSDKLogger logger,
  }) => LiveKitCallSession._(container, otherPartyChannelDid, logger);

  // ---------------------------------------------------------------------------
  // CallSession interface
  // ---------------------------------------------------------------------------

  @override
  Stream<AudioVideoCallState> get state {
    late final StreamController<AudioVideoCallState> controller;
    StreamSubscription<AudioVideoCallState>? sourceSubscription;
    controller = StreamController<AudioVideoCallState>(
      onListen: () {
        sourceSubscription = _stateController.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.add(_latestState);
      },
      onCancel: () => sourceSubscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) {
    _logger.info('Microphone enabled: $enabled', name: _logKey);
    return _container
        .read(audioVideoCallServiceProvider(_otherPartyChannelDid).notifier)
        .setMicrophoneEnabled(enabled);
  }

  @override
  Future<void> setCameraEnabled(bool enabled) {
    _logger.info('Camera enabled: $enabled', name: _logKey);
    return _container
        .read(audioVideoCallServiceProvider(_otherPartyChannelDid).notifier)
        .setCameraEnabled(enabled);
  }

  @override
  Future<void> switchCamera() {
    _logger.info('Switching camera', name: _logKey);
    return _container
        .read(audioVideoCallServiceProvider(_otherPartyChannelDid).notifier)
        .switchCamera();
  }

  @override
  Future<void> setSpeakerphoneEnabled(bool enabled) {
    _logger.info('Speakerphone enabled: $enabled', name: _logKey);
    return _container
        .read(audioVideoCallServiceProvider(_otherPartyChannelDid).notifier)
        .setSpeakerphoneEnabled(enabled);
  }

  @override
  Future<void> hangUp() {
    _logger.info(
      'Hanging up call for ${_otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
    return _container
        .read(audioVideoCallServiceProvider(_otherPartyChannelDid).notifier)
        .leaveCall();
  }

  // ---------------------------------------------------------------------------
  // Plugin-internal accessors
  // ---------------------------------------------------------------------------

  /// The other party's channel DID used to key the call service provider.
  String get otherPartyChannelDid => _otherPartyChannelDid;

  /// The Riverpod container backing this session.
  ///
  /// Accessible to plugin-internal code (`MeetingPlaceLiveKitCallPlugin` and
  /// `AudioVideoCallView`) to resolve providers scoped to this call.
  ProviderContainer get container => _container;

  /// Disposes the Riverpod container backing this session.
  ///
  /// Called by `MeetingPlaceLiveKitCallPlugin` when the session is no longer
  /// needed. After disposal the session must not be used again.
  void disposeContainer() {
    _logger.info(
      'Disposing session for ${_otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
    _stateSub.close();
    _stateController.close();
    _container.dispose();
  }
}
