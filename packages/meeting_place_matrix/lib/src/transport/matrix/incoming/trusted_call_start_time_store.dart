/// @docImport 'call_outcome_handler.dart';
/// @docImport 'call_started_handler.dart';
library;

/// Tracks the trustworthy call start time (a `mpx.call.started` event's
/// homeserver `originServerTs`) for each `callId`.
///
/// Shared between [CallStartedHandler] and [CallOutcomeHandler] so the
/// latter can substitute this value for the sender-supplied `startedAt` in
/// a later `mpx.call.outcome` event.
class TrustedCallStartTimeStore {
  static const _maxRememberedCalls = 1000;

  final Map<String, DateTime> _startedAtByCallId = {};

  /// Records [startedAt] for [callId] if none is recorded yet.
  ///
  /// The first `mpx.call.started` event observed for a call is authoritative:
  /// later duplicates only reflect other devices noticing the same connect
  /// slightly later, so they must not override the earlier, more accurate
  /// timestamp.
  void recordIfAbsent(String callId, DateTime startedAt) {
    if (_startedAtByCallId.containsKey(callId)) return;
    _startedAtByCallId[callId] = startedAt;
    if (_startedAtByCallId.length > _maxRememberedCalls) {
      _startedAtByCallId.remove(_startedAtByCallId.keys.first);
    }
  }

  /// Returns the trustworthy start time for [callId], or `null` if no
  /// `mpx.call.started` event has been seen for it (e.g. the sender predates
  /// this feature).
  DateTime? operator [](String callId) => _startedAtByCallId[callId];
}
