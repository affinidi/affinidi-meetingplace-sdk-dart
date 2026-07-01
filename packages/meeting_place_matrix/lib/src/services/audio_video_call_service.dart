import 'dart:async';

import 'package:matrix/matrix.dart' as matrix;

import '../../meeting_place_matrix.dart';
import '../constants/audio_video_call_defaults.dart';
import '../handlers/call_e2ee_handler.dart';
import 'matrix_call_adapter.dart';
import 'sfu_token_service.dart';

/// Orchestrates the LiveKit call state machine for one active call session.
///
/// Constructs two focused collaborators at creation time:
/// - [MatrixCallAdapter] for channel/credential resolution and all Matrix
///   and control-plane interactions.
/// - [CallE2EEHandler] for per-participant E2EE key tracking and keyframe
///   nudges.
///
/// This class owns the call state, timers, and participant-change callbacks.
/// Call [dispose] when the session ends. The service must not be used after
/// [dispose] returns.
class AudioVideoCallService {
  AudioVideoCallService({
    required this.otherPartyChannelDid,
    required MeetingPlaceMatrixSDK sdk,
    required Uri? livekitSfuUrl,
    required Duration e2eeReadyTimeout,
    required Duration outgoingCallTimeout,
    required matrix.WebRTCDelegate rtcDelegate,
    required MeetingPlaceMatrixSDKLogger logger,
    required SfuTokenService livekitTokenService,
    required LiveKitRoom room,
  }) : _logger = logger,
       _room = room,
       _e2eeReadyTimeout = e2eeReadyTimeout,
       _outgoingCallTimeout = outgoingCallTimeout,
       _coordinator = MatrixCallAdapter(
         sdk: sdk,
         logger: logger,
         otherPartyChannelDid: otherPartyChannelDid,
         livekitSfuUrl: livekitSfuUrl,
         livekitTokenService: livekitTokenService,
         rtcDelegate: rtcDelegate,
       ) {
    _e2eeHandler = CallE2EEHandler(
      room: room,
      logger: logger,
      isDisposed: () => _isDisposed,
      onAllKeyed: _onAllKeyed,
    );
  }

  static const _logKey = 'AudioVideoCallService';

  final String otherPartyChannelDid;
  final MeetingPlaceMatrixSDKLogger _logger;
  final LiveKitRoom _room;
  final Duration _e2eeReadyTimeout;
  final Duration _outgoingCallTimeout;
  final MatrixCallAdapter _coordinator;
  late final CallE2EEHandler _e2eeHandler;

  AudioVideoCallState _state = AudioVideoCallState.initial;
  final StreamController<AudioVideoCallState> _stateController =
      StreamController<AudioVideoCallState>.broadcast();

  bool _isDisposed = false;
  bool _isTearingDown = false;
  Timer? _e2eeReadyTimer;
  Timer? _outgoingCallTimer;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  AudioVideoCallState get state => _state;

  /// Live stream of [AudioVideoCallState] emitted on every change.
  Stream<AudioVideoCallState> get stateStream => _stateController.stream;

  /// The LiveKit room backing this call session.
  LiveKitRoom get room => _room;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Releases all resources held by this service.
  ///
  /// Cancels timers, leaves the Matrix call if in progress, and disconnects
  /// the LiveKit room. Must be called when the session ends. The service must
  /// not be used after [dispose] returns.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _e2eeReadyTimer?.cancel();
    _outgoingCallTimer?.cancel();
    _e2eeHandler.cancelAll();
    final roomId = _coordinator.matrixRoomId;
    final callId = _coordinator.matrixCallId;
    if (roomId != null && callId != null) {
      unawaited(_coordinator.leaveCall());
    }
    // Ensure the LiveKit room is always released, even if leaveCall() was
    // never called (e.g. screen popped mid-call or app killed).
    unawaited(_room.disconnect());
    await _stateController.close();
  }

  void _setState(AudioVideoCallState value) {
    _state = value;
    if (!_stateController.isClosed) _stateController.add(value);
  }

  // ---------------------------------------------------------------------------
  // Public lifecycle methods
  // ---------------------------------------------------------------------------

  Future<void> joinCall({
    bool isRecipient = false,
    CallMediaType mediaType = CallMediaType.video,
  }) async {
    if (_isDisposed) {
      _logger.info('joinCall: Skipping, service disposed', name: _logKey);
      return;
    }
    _e2eeHandler.reset();
    _setState(
      _state.copyWith(
        status: AudioVideoCallStatus.connecting,
        clearErrorCode: true,
      ),
    );

    var errorCode = AudioVideoCallErrorCode.unexpected;
    var succeeded = false;
    try {
      errorCode = AudioVideoCallErrorCode.channelNotFound;
      final (:channel, :ownChannelDid, :roomName) = await _coordinator
          .resolveChannel();

      errorCode = AudioVideoCallErrorCode.tokenFetchFailed;
      final (
        :didManager,
        :matrixRoomId,
        :sfuUrl,
        :sfuToken,
        :participantIdToDid,
      ) = await _coordinator.fetchCallCredentials(
        channel: channel,
        ownChannelDid: ownChannelDid,
        roomName: roomName,
      );

      errorCode = AudioVideoCallErrorCode.connectionFailed;
      final (:callAlreadyInProgress, :callId) = await _coordinator
          .prepareCallSession(
            didManager: didManager,
            matrixRoomId: matrixRoomId,
            isRecipient: isRecipient,
          );

      await _room.setSharedKey('mpx-call-shared-key:$matrixRoomId');

      if (!isRecipient) {
        errorCode = AudioVideoCallErrorCode.callInviteFailed;
        await _coordinator.sendCallInvite(
          channel: channel,
          callAlreadyInProgress: callAlreadyInProgress,
          mediaType: mediaType,
        );
      }

      errorCode = AudioVideoCallErrorCode.connectionFailed;
      await _room.connect(
        url: sfuUrl,
        token: sfuToken,
        participantIdToDid: participantIdToDid,
        onE2EEStateChanged: _e2eeHandler.onE2EEStateChanged,
        onParticipantDisconnected: _onParticipantDisconnected,
        onParticipantsChanged: _onParticipantsChanged,
      );

      final isJoiningExistingCall = isRecipient || callAlreadyInProgress;
      _setState(
        _state.copyWith(
          ownRole: isJoiningExistingCall ? CallRole.recipient : CallRole.caller,
        ),
      );

      await _enableLocalMedia(mediaType: mediaType);
      await _coordinator.registerMatrixCall(
        didManager: didManager,
        matrixRoomId: matrixRoomId,
        callId: callId,
        sfuUrl: sfuUrl,
        roomName: roomName,
      );

      if (_isDisposed) {
        _logger.info(
          'joinCall: Skipping post-connect state, service disposed',
          name: _logKey,
        );
        return;
      }

      final ownRole = isJoiningExistingCall
          ? CallRole.recipient
          : CallRole.caller;
      final hasPeer = _hasPeer;
      if (ownRole == CallRole.caller && !hasPeer) {
        _logger.info(
          'joinCall: Caller alone in room, starting outgoing ring timer '
          '(${_outgoingCallTimeout.inSeconds}s)',
          name: _logKey,
        );
        _setState(
          _state.copyWith(
            status: AudioVideoCallStatus.outgoingRinging,
            participants: _room.participants,
            ownRole: ownRole,
          ),
        );
        _outgoingCallTimer = Timer(
          _outgoingCallTimeout,
          _onOutgoingCallTimeout,
        );
      } else {
        _setState(
          _state.copyWith(
            status: AudioVideoCallStatus.waitingForKeys,
            participants: _room.participants,
            ownRole: ownRole,
          ),
        );
        _e2eeReadyTimer = Timer(_e2eeReadyTimeout, _onE2EETimeout);
      }
      succeeded = true;
    } on MeetingPlaceLiveKitCallOperationException catch (e, stackTrace) {
      if (_isDisposed || _isTearingDown) {
        _logger.info(
          'joinCall: Swallowing operation error, call torn down',
          name: _logKey,
        );
        return;
      }
      _logger.error(
        'Failed to join call',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );
      _setState(
        _state.copyWith(
          status: AudioVideoCallStatus.error,
          errorCode: errorCode,
        ),
      );
    } catch (e, stackTrace) {
      if (_isDisposed || _isTearingDown) {
        _logger.info(
          'joinCall: Swallowing unexpected error, call torn down',
          name: _logKey,
        );
        return;
      }
      _logger.error(
        'Unexpected error joining call',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );
      _setState(
        _state.copyWith(
          status: AudioVideoCallStatus.error,
          errorCode: AudioVideoCallErrorCode.unexpected,
        ),
      );
    } finally {
      if (!succeeded) unawaited(_room.disconnect());
    }
  }

  /// Leaves the LiveKit room gracefully.
  Future<void> leaveCall() async {
    if (_isDisposed) {
      _logger.info('leaveCall: Skipping, service disposed', name: _logKey);
      return;
    }
    _isTearingDown = true;

    const preAnswerStatuses = {
      AudioVideoCallStatus.connecting,
      AudioVideoCallStatus.outgoingRinging,
    };
    final cancelledBeforeAnswer =
        _state.ownRole == CallRole.caller &&
        !_hasPeer &&
        preAnswerStatuses.contains(_state.status);
    _setState(_state.copyWith(status: AudioVideoCallStatus.disconnecting));
    _e2eeReadyTimer?.cancel();
    _outgoingCallTimer?.cancel();
    _e2eeHandler.cancelAll();

    if (cancelledBeforeAnswer) _coordinator.sendCallCancelToRecipient();

    try {
      await _coordinator.leaveCall();
      await _room.disconnect();
    } catch (e, stackTrace) {
      _logger.warning(
        'leaveCall: Ignoring teardown error during call cancellation: $e\n'
        '$stackTrace',
        name: _logKey,
      );
    } finally {
      if (!_isDisposed) {
        _setState(
          _state.copyWith(
            status: AudioVideoCallStatus.disconnected,
            participants: <AudioVideoCallParticipant>[],
          ),
        );
      }
    }
  }

  /// Enables or disables the local microphone.
  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (_isDisposed) {
      _logger.info(
        'setMicrophoneEnabled: Skipping, service disposed',
        name: _logKey,
      );
      return;
    }
    await _room.setMicrophoneEnabled(enabled);
    _setState(_state.copyWith(participants: _room.participants));
  }

  /// Enables or disables the local camera.
  Future<void> setCameraEnabled(bool enabled) async {
    if (_isDisposed) {
      _logger.info(
        'setCameraEnabled: Skipping, service disposed',
        name: _logKey,
      );
      return;
    }
    await _room.setCameraEnabled(enabled);
    _setState(_state.copyWith(participants: _room.participants));
  }

  /// Switches between front and rear camera.
  Future<void> switchCamera() async {
    if (_isDisposed) return;
    await _room.switchCamera();
  }

  /// Routes audio through the loudspeaker ([enabled] = true) or earpiece
  /// ([enabled] = false).
  ///
  /// The presentation layer determines the initial value based on contact type
  /// and call mode, then calls this method on each user toggle. No-op when
  /// disposed.
  Future<void> setSpeakerphoneEnabled(bool enabled) async {
    if (_isDisposed) {
      _logger.info(
        'setSpeakerphoneEnabled: Skipping, service disposed',
        name: _logKey,
      );
      return;
    }
    await _room.setSpeakerphoneEnabled(enabled);
  }

  /// Called by the plugin when a `call-decline` signal arrives from the callee.
  ///
  /// No-ops silently if the service is disposed or not in
  /// [AudioVideoCallStatus.outgoingRinging].
  void notifyDeclined() {
    if (_isDisposed) {
      _logger.info('notifyDeclined: Skipping, service disposed', name: _logKey);
      return;
    }
    if (_state.status != AudioVideoCallStatus.outgoingRinging) return;
    _logger.info(
      'notifyDeclined: Callee declined, leaving room and emitting declined',
      name: _logKey,
    );
    _outgoingCallTimer?.cancel();
    _outgoingCallTimer = null;
    unawaited(_coordinator.leaveCall());
    unawaited(_room.disconnect());
    _setState(
      _state.copyWith(
        status: AudioVideoCallStatus.declined,
        participants: <AudioVideoCallParticipant>[],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  bool get _hasPeer => _room.participants.any((p) => !p.isSelf);

  Future<void> _enableLocalMedia({
    CallMediaType mediaType = CallMediaType.video,
  }) async {
    try {
      await _room.setMicrophoneEnabled(true);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to enable microphone',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );
    }
    if (mediaType == CallMediaType.audio) return;
    try {
      await _room.setCameraEnabled(true);
    } catch (e) {
      _logger.warning(
        '_enableLocalMedia: camera unavailable, continuing with audio only',
        name: _logKey,
      );
    }
  }

  void _onParticipantsChanged() {
    if (_isDisposed) {
      _logger.info(
        '_onParticipantsChanged: Skipping, service disposed',
        name: _logKey,
      );
      return;
    }
    if (_state.status == AudioVideoCallStatus.outgoingRinging && _hasPeer) {
      _logger.info(
        '_onParticipantsChanged: Other participant joined, '
        'outgoingRinging -> waitingForKeys',
        name: _logKey,
      );
      _outgoingCallTimer?.cancel();
      _outgoingCallTimer = null;
      _setState(
        _state.copyWith(
          status: AudioVideoCallStatus.waitingForKeys,
          participants: _room.participants,
        ),
      );
      _e2eeReadyTimer ??= Timer(_e2eeReadyTimeout, _onE2EETimeout);
      return;
    }
    _setState(_state.copyWith(participants: _room.participants));
  }

  void _onParticipantDisconnected(String participantId) {
    if (_isDisposed) {
      _logger.info(
        '_onParticipantDisconnected: Skipping, service disposed',
        name: _logKey,
      );
      return;
    }
    if (!AudioVideoCallDefaults.sharedKeyEncryption) {
      final ownParticipantId = _room.ownParticipantId;
      if (ownParticipantId != null) {
        unawaited(_room.ratchetKey(ownParticipantId, 0));
      }
    }
    _setState(_state.copyWith(participants: _room.participants));
  }

  void _onAllKeyed() {
    _e2eeReadyTimer?.cancel();
    if (_state.status == AudioVideoCallStatus.waitingForKeys ||
        _state.status == AudioVideoCallStatus.connected) {
      _setState(
        _state.copyWith(
          status: AudioVideoCallStatus.active,
          participants: _room.participants,
        ),
      );
    }
  }

  void _onOutgoingCallTimeout() {
    if (_isDisposed) {
      _logger.info(
        '_onOutgoingCallTimeout: Skipping, service disposed',
        name: _logKey,
      );
      return;
    }
    if (_state.status != AudioVideoCallStatus.outgoingRinging) return;
    _logger.info(
      '_onOutgoingCallTimeout: No answer after '
      '${_outgoingCallTimeout.inSeconds}s, '
      'leaving room and emitting missed',
      name: _logKey,
    );
    unawaited(_coordinator.leaveCall());
    unawaited(_room.disconnect());
    _coordinator.sendCallCancelToRecipient();
    _setState(
      _state.copyWith(
        status: AudioVideoCallStatus.missed,
        participants: <AudioVideoCallParticipant>[],
      ),
    );
  }

  void _onE2EETimeout() {
    if (_isDisposed) {
      _logger.info('_onE2EETimeout: Skipping, service disposed', name: _logKey);
      return;
    }
    if (_state.status == AudioVideoCallStatus.waitingForKeys) {
      _setState(
        _state.copyWith(
          status: AudioVideoCallStatus.connected,
          participants: _room.participants,
        ),
      );
    }
  }
}
