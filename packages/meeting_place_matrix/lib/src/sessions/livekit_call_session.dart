import 'dart:async';

import '../../meeting_place_matrix.dart';
import '../logger/top_and_tail_extension.dart';

/// Concrete [AudioVideoCallSession] for a LiveKit-backed call.
///
/// Wraps an [AudioVideoCallService] and delegates all operations to it.
/// Created by `MeetingPlaceLiveKitCallPlugin` on `startCall` or `acceptCall`
/// and handed to the caller as the live handle.
///
/// The session is single-use: once [hangUp] is called the service is disposed
/// and the session must be discarded.
class LiveKitCallSession implements AudioVideoCallSession {
  LiveKitCallSession._({
    required AudioVideoCallService service,
    required String otherPartyChannelDid,
    required MeetingPlaceMatrixSDKLogger logger,
  }) : _service = service,
       _otherPartyChannelDid = otherPartyChannelDid,
       _logger = logger {
    _stateController = StreamController<AudioVideoCallState>.broadcast();
    _stateSub = service.stateStream.listen((AudioVideoCallState next) {
      _latestState = next;
      if (!_stateController.isClosed) _stateController.add(next);
    });
  }

  final AudioVideoCallService _service;
  final String _otherPartyChannelDid;
  final MeetingPlaceMatrixSDKLogger _logger;
  late final StreamController<AudioVideoCallState> _stateController;
  late final StreamSubscription<AudioVideoCallState> _stateSub;

  // Latest state pushed by the service. Replayed to late subscribers so a
  // transient emission (e.g. the one carrying ownRole) is never missed if
  // the caller subscribes after the service has already moved on.
  AudioVideoCallState _latestState = AudioVideoCallState.initial;

  static const _logKey = 'LiveKitCallSession';

  /// Factory used only by `MeetingPlaceLiveKitCallPlugin`.
  static LiveKitCallSession create({
    required AudioVideoCallService service,
    required String otherPartyChannelDid,
    required MeetingPlaceMatrixSDKLogger logger,
  }) => LiveKitCallSession._(
    service: service,
    otherPartyChannelDid: otherPartyChannelDid,
    logger: logger,
  );

  // ---------------------------------------------------------------------------
  // AudioVideoCallSession interface
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
    return _service.setMicrophoneEnabled(enabled);
  }

  @override
  Future<void> setCameraEnabled(bool enabled) {
    _logger.info('Camera enabled: $enabled', name: _logKey);
    return _service.setCameraEnabled(enabled);
  }

  @override
  Future<void> switchCamera() {
    _logger.info('Switching camera', name: _logKey);
    return _service.switchCamera();
  }

  @override
  Future<void> setSpeakerphoneEnabled(bool enabled) {
    _logger.info('Speakerphone enabled: $enabled', name: _logKey);
    return _service.setSpeakerphoneEnabled(enabled);
  }

  @override
  Future<void> hangUp() {
    _logger.info(
      'Hanging up call for ${_otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
    return _service.leaveCall();
  }

  // ---------------------------------------------------------------------------
  // Plugin-internal accessors
  // ---------------------------------------------------------------------------

  /// The other party's channel DID used to key this call session.
  String get otherPartyChannelDid => _otherPartyChannelDid;

  /// The LiveKit room backing this session.
  ///
  /// Exposed so Flutter consumer widgets can access the room for video
  /// rendering without going through Riverpod providers.
  LiveKitRoom get room => _service.room;

  /// Initiates the call connection. Plugin-internal — called by
  /// `MeetingPlaceLiveKitCallPlugin` immediately after creating the session.
  Future<void> joinCall({
    bool isRecipient = false,
    CallMediaType mediaType = CallMediaType.video,
  }) => _service.joinCall(isRecipient: isRecipient, mediaType: mediaType);

  /// Notifies the service that the callee declined. Plugin-internal — called
  /// by `MeetingPlaceLiveKitCallPlugin` when a decline signal is received.
  void notifyDeclined() => _service.notifyDeclined();

  /// Disposes the service backing this session.
  ///
  /// Called by `MeetingPlaceLiveKitCallPlugin` when the session is no longer
  /// needed. After disposal the session must not be used again.
  Future<void> dispose() async {
    _logger.info(
      'Disposing session for ${_otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
    await _stateSub.cancel();
    await _stateController.close();
    await _service.dispose();
  }
}
