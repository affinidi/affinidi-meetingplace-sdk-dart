import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart'
    show AudioVideoCallSession, AudioVideoCallState;
import 'package:meeting_place_core/meeting_place_core.dart'
    show MeetingPlaceCoreSDKLogger;

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
  LiveKitCallSession._({
    required ProviderContainer container,
    required String otherPartyChannelDid,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _container = container,
       _otherPartyChannelDid = otherPartyChannelDid,
       _logger = logger;

  final ProviderContainer _container;
  final String _otherPartyChannelDid;
  final MeetingPlaceCoreSDKLogger _logger;

  static const _logKey = 'LiveKitCallSession';

  /// Factory used only by `MeetingPlaceLiveKitCallPlugin`.
  static LiveKitCallSession create({
    required ProviderContainer container,
    required String otherPartyChannelDid,
    required MeetingPlaceCoreSDKLogger logger,
  }) => LiveKitCallSession._(
    container: container,
    otherPartyChannelDid: otherPartyChannelDid,
    logger: logger,
  );

  // ---------------------------------------------------------------------------
  // CallSession interface
  // ---------------------------------------------------------------------------

  @override
  Stream<AudioVideoCallState> get state {
    final controller = StreamController<AudioVideoCallState>.broadcast();
    final sub = _container.listen(
      audioVideoCallServiceProvider(_otherPartyChannelDid),
      (_, AudioVideoCallState next) {
        if (!controller.isClosed) controller.add(next);
      },
      fireImmediately: true,
    );
    controller.onCancel = () {
      sub.close();
      controller.close();
    };
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
    _container.dispose();
  }
}
