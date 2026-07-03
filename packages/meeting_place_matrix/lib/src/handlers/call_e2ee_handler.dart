import 'dart:async';

import '../interfaces/livekit_room.dart';
import '../logger/meeting_place_matrix_sdk_logger.dart';
import '../models/call_e2ee_state.dart';

/// Tracks per-participant E2EE key state and manages keyframe nudges.
///
/// Isolates all mutable key-tracking state from the call service so the
/// service stays focused on the call state machine. Owned by the service;
/// constructed at service creation time.
///
/// Call [reset] at the start of each `joinCall` to clear stale state from a
/// previous call generation on the same service instance. Call [cancelAll]
/// when tearing down the session.
class CallE2EEHandler {
  CallE2EEHandler({
    required LiveKitRoom room,
    required MeetingPlaceMatrixSDKLogger logger,
    required bool Function() isDisposed,
    required void Function() onAllKeyed,
  }) : _room = room,
       _logger = logger,
       _isDisposed = isDisposed,
       _onAllKeyed = onAllKeyed;

  final LiveKitRoom _room;
  final MeetingPlaceMatrixSDKLogger _logger;
  final bool Function() _isDisposed;
  final void Function() _onAllKeyed;

  static const _logKey = 'CallE2EEHandler';

  /// Participants whose media currently reports a missing decryption key.
  ///
  /// Populated from [onE2EEStateChanged] and used only to drive the
  /// waitingForKeys → active state transition. We deliberately do NOT send
  /// explicit `encryption_keys_request` events: matrix performs its own
  /// membership-driven key exchange on join, and an explicit request arriving
  /// after a membership re-sync makes the publisher's matrix layer lose its
  /// local key ("no keys found"), regenerate it, and churn index 0 with an
  /// inconsistent key, which strands the decoder on a black frame.
  final Set<String> _participantsMissingKey = {};

  /// Participants whose media has successfully decrypted at least once
  /// (reached [CallE2EEState.ok]).
  final Set<String> _participantsKeyed = {};

  /// Active keyframe-nudge timers keyed by participant id. A timer forces the
  /// SFU to resend a keyframe so a decoder stuck on a missing key recovers once
  /// matrix's native key exchange delivers the publisher key.
  final Map<String, Timer> _keyframeNudgeTimers = {};

  /// Number of keyframe nudges already issued per participant.
  final Map<String, int> _keyframeNudgeAttempts = {};

  /// Upper bound on keyframe nudges per participant before giving up.
  static const _maxKeyframeNudges = 5;

  /// Delay between keyframe nudges, giving matrix's to-device key exchange time
  /// to deliver and apply the publisher key before each retry.
  static const _keyframeNudgeInterval = Duration(seconds: 2);

  /// Clears all per-participant tracking. Call at the start of each
  /// `joinCall` so a fresh call generation does not inherit stale state.
  void reset() {
    _participantsKeyed.clear();
    _participantsMissingKey.clear();
    cancelAll();
  }

  /// Cancels all in-flight keyframe nudge timers.
  void cancelAll() {
    for (final timer in _keyframeNudgeTimers.values) {
      timer.cancel();
    }
    _keyframeNudgeTimers.clear();
    _keyframeNudgeAttempts.clear();
  }

  /// Processes an E2EE state update from the LiveKit room for [participantId].
  ///
  /// When all participants reach [CallE2EEState.ok], invokes `onAllKeyed` so
  /// the call service can drive the `waitingForKeys → active` transition.
  void onE2EEStateChanged(String participantId, CallE2EEState e2eeState) {
    if (_isDisposed()) {
      _logger.info(
        'onE2EEStateChanged: Skipping, service disposed',
        name: _logKey,
      );
      return;
    }
    _logger.info(
      'onE2EEStateChanged: participant=$participantId state=$e2eeState',
      name: _logKey,
    );
    if (e2eeState == CallE2EEState.ok) {
      _participantsKeyed.add(participantId);
      _participantsMissingKey.remove(participantId);
      _cancelKeyframeNudge(participantId);
      _onAllKeyed();
    } else if (e2eeState == CallE2EEState.missingKey) {
      _participantsMissingKey.add(participantId);
      _scheduleKeyframeNudge(participantId);
    }
  }

  void _scheduleKeyframeNudge(String participantId) {
    if (_keyframeNudgeTimers.containsKey(participantId)) return;
    _logger.info(
      '_scheduleKeyframeNudge: starting for $participantId',
      name: _logKey,
    );
    _keyframeNudgeAttempts[participantId] = 0;
    _keyframeNudgeTimers[participantId] = Timer.periodic(
      _keyframeNudgeInterval,
      (timer) {
        if (_isDisposed() ||
            _participantsKeyed.contains(participantId) ||
            !_participantsMissingKey.contains(participantId)) {
          _cancelKeyframeNudge(participantId);
          return;
        }
        final attempts = (_keyframeNudgeAttempts[participantId] ?? 0) + 1;
        _keyframeNudgeAttempts[participantId] = attempts;
        if (attempts > _maxKeyframeNudges) {
          _logger.warning(
            '_scheduleKeyframeNudge: giving up on $participantId after '
            '$_maxKeyframeNudges attempts',
            name: _logKey,
          );
          _cancelKeyframeNudge(participantId);
          return;
        }
        _logger.info(
          '_scheduleKeyframeNudge: nudge $attempts for $participantId',
          name: _logKey,
        );
        unawaited(_room.forceRemoteKeyframe(participantId));
      },
    );
  }

  void _cancelKeyframeNudge(String participantId) {
    _keyframeNudgeTimers.remove(participantId)?.cancel();
    _keyframeNudgeAttempts.remove(participantId);
  }
}
