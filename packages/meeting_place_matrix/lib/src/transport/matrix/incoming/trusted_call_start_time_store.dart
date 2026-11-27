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

  /// Records [startedAt] for [callId], keeping the earliest timestamp seen.
  ///
  /// The earliest `mpx.call.started` timestamp for a call is authoritative:
  /// later duplicates only reflect other devices noticing the same connect
  /// slightly later, so they must not override an earlier, more accurate
  /// timestamp, regardless of the order in which events are delivered.
  void recordIfAbsent(String callId, DateTime startedAt) {
    final existing = _startedAtByCallId.remove(callId);
    final earliest = existing == null || startedAt.isBefore(existing)
        ? startedAt
        : existing;
    _startedAtByCallId[callId] = earliest;
    if (_startedAtByCallId.length > _maxRememberedCalls) {
      _startedAtByCallId.remove(_startedAtByCallId.keys.first);
    }
  }

  /// Returns the trustworthy start time for [callId], or `null` if no
  /// `mpx.call.started` event has been seen for it (e.g. the sender predates
  /// this feature). Marks [callId] as recently used, protecting it from
  /// eviction ahead of calls no longer being looked up.
  DateTime? operator [](String callId) {
    final startedAt = _startedAtByCallId.remove(callId);
    if (startedAt == null) return null;
    _startedAtByCallId[callId] = startedAt;
    return startedAt;
  }
}
