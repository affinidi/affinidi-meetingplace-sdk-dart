import 'dart:async';

import 'package:meeting_place_chat/src/logger/meeting_place_chat_sdk_logger.dart';

/// Manages the typing-indicator lifecycle for a single chat session.
///
/// Owns the active/idle state, the auto-stop timer that clears the indicator
/// after expiry of inactivity, and the keep-alive timer that refreshes the
/// server-side timeout while the user is still typing.
class TypingIndicatorManager {
  TypingIndicatorManager({
    required Future<void> Function(bool active) onSetTypingState,
    required Duration expiry,
    required MeetingPlaceChatSDKLogger logger,
  }) : _onSetTypingState = onSetTypingState,
       _expiry = expiry,
       _logger = logger;

  final Future<void> Function(bool active) _onSetTypingState;
  final Duration _expiry;
  final MeetingPlaceChatSDKLogger _logger;

  bool _isActive = false;
  Timer? _keepAliveTimer;
  Timer? _autoStopTimer;

  static const _logKey = 'TypingIndicatorManager';

  Duration get _keepAliveInterval => _expiry * 2 ~/ 3;

  /// Signals that the user is typing. Starts the indicator on first call and
  /// resets the inactivity timer on each subsequent call.
  Future<void> sendActivity() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(_expiry, stop);

    if (!_isActive) {
      _isActive = true;
      await _onSetTypingState(true);
      _scheduleKeepAlive();
    }
  }

  /// Clears the typing indicator and cancels all timers.
  void stop() {
    _isActive = false;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
  }

  void _scheduleKeepAlive() {
    _keepAliveTimer = Timer(_keepAliveInterval, () async {
      _keepAliveTimer = null;
      if (!_isActive) return;
      try {
        await _onSetTypingState(false);
        if (!_isActive) return;
        await _onSetTypingState(true);
        if (_isActive) _scheduleKeepAlive();
      } catch (e, st) {
        _logger.error(
          'Typing keep-alive failed',
          name: _logKey,
          error: e,
          stackTrace: st,
        );
        _isActive = false;
      }
    });
  }
}
