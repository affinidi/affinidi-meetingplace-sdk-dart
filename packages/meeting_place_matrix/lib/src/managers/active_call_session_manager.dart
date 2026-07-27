import 'dart:async';

import '../../meeting_place_matrix.dart';
import '../utils/string.dart';
import 'pending_call_manager.dart';

/// Owns the active call session and stale-session disposal sequencing.
class ActiveCallSessionManager {
  ActiveCallSessionManager({
    required PendingCallManager pendingCallManager,
    required MeetingPlaceMatrixSDKLogger logger,
  }) : _pendingCallManager = pendingCallManager,
       _logger = logger;

  final PendingCallManager _pendingCallManager;
  final MeetingPlaceMatrixSDKLogger _logger;

  LiveKitCallSession? _activeSession;
  Future<void>? _pendingSessionDispose;

  static const _logKey = 'ActiveCallSessionManager';

  /// The currently active session, or null when no call is active.
  LiveKitCallSession? get activeSession => _activeSession;

  /// Waits for a previously-started stale-session disposal to complete.
  Future<void> awaitPendingDisposal() async {
    final methodName = 'awaitPendingDisposal';

    final pendingSessionDispose = _pendingSessionDispose;
    if (pendingSessionDispose == null) {
      _logger.info(
        '$methodName: No pending session disposal to await',
        name: _logKey,
      );
      return;
    }

    _logger.info(
      '$methodName: Awaiting pending session disposal before new join',
      name: _logKey,
    );
    await pendingSessionDispose;
    _pendingSessionDispose = null;
  }

  /// Registers [session] as active and releases the busy guard on ended
  /// states.
  void setActiveSession(LiveKitCallSession session) {
    _activeSession = session;
    _watchForSessionEnd(session);
  }

  /// Clears the active session reference and the busy guard without disposal.
  void clearActiveSession() {
    _activeSession = null;
    _pendingCallManager.clearActiveCall();
  }

  /// Disposes the current active session before starting a replacement call.
  Future<void> disposeCurrentSessionForReplacement() async {
    final methodName = 'disposeCurrentSessionForReplacement';

    final previousSession = _activeSession;
    if (previousSession == null) {
      _logger.info('$methodName: No active session to dispose', name: _logKey);
      return;
    }

    _logger.warning(
      '$methodName: Disposing previous active session '
      'for ${previousSession.otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
    _activeSession = null;
    _pendingCallManager.clearActiveCall();
    _pendingSessionDispose = previousSession.dispose().catchError((Object e) {
      _logger.warning(
        '$methodName: Error during previous session '
        'disposal: $e',
        name: _logKey,
      );
    });
    _logger.info(
      '$methodName: Awaiting disposal of '
      '${previousSession.otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
    await _pendingSessionDispose;
    _logger.info(
      '$methodName: Previous session disposal complete',
      name: _logKey,
    );
    _pendingSessionDispose = null;
  }

  /// Disposes [session] after a peer restart and tracks the in-flight teardown.
  void disposeSessionAfterPeerRestart(LiveKitCallSession session) {
    final methodName = 'disposeSessionAfterPeerRestart';

    _pendingSessionDispose = session.dispose().catchError((Object e) {
      _logger.warning(
        '$methodName: Error during previous session '
        'disposal: $e',
        name: _logKey,
      );
    });
  }

  /// Hangs up and disposes the active session, if present.
  Future<void> leaveCurrentCall() async {
    final methodName = 'leaveCurrentCall';

    final session = _activeSession;
    if (session == null) {
      _logger.info('$methodName: No active session to leave', name: _logKey);
      return;
    }

    _logger.info(
      'Leaving current call for ${session.otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
    await session.hangUp();
    await session.dispose();
    _activeSession = null;
    _pendingCallManager.clearActiveCall();
  }

  /// Disposes any owned session state during plugin shutdown.
  Future<void> dispose() async {
    await _pendingSessionDispose;
    _pendingSessionDispose = null;
    await _activeSession?.dispose();
    _activeSession = null;
    _pendingCallManager.clearActiveCall();
  }

  /// Watches ended session states and releases the busy guard.
  void _watchForSessionEnd(LiveKitCallSession session) {
    final methodName = 'watchForSessionEnd';

    const endedStatuses = {
      AudioVideoCallStatus.ended,
      AudioVideoCallStatus.declined,
      AudioVideoCallStatus.missed,
      AudioVideoCallStatus.disconnected,
      AudioVideoCallStatus.error,
    };

    void release(String reason) {
      if (_activeSession == session) {
        _logger.info(
          '$methodName: ${reason[0].toUpperCase()}${reason.substring(1)} '
          'releasing busy guard for '
          '${session.otherPartyChannelDid.topAndTail()}',
          name: _logKey,
        );
        _activeSession = null;
        _pendingCallManager.clearActiveCall();
      }
    }

    session.state
        .where((state) => endedStatuses.contains(state.status))
        .listen(
          (_) => release('call ended'),
          onDone: () => release('session stream closed'),
          onError: (_) => release('session stream error'),
          cancelOnError: true,
        );
  }
}
