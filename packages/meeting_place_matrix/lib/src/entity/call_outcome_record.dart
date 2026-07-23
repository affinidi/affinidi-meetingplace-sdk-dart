/// The canonical wire-level outcome of a call session.
///
/// Shared by both sides of the call. Each device maps this into a local
/// status using its own role (caller vs recipient) so the chat item wording
/// can remain asymmetric while the underlying fact stays shared.
enum CallOutcome {
  /// Call invite is live or the call is in progress.
  ongoing,

  /// Caller cancelled before the recipient answered.
  cancelled,

  /// Recipient explicitly rejected before answering.
  declined,

  /// No answer before the ring timeout.
  timedOut,

  /// At least one recipient answered and the call ended normally.
  ended,
}

/// Minimal canonical record of a call session's terminal state.
///
/// Both sides of a call read from the same [CallOutcomeRecord] before mapping
/// the outcome into their local call chat item state. The local
/// caller/recipient display asymmetry lives in the render mapping, not here.
class CallOutcomeRecord {
  const CallOutcomeRecord({
    required this.callId,
    required this.outcome,
    required this.answered,
    this.startedAt,
    this.endedAt,
  });

  /// Reads a record from a transport [map], or `null` when it is absent or
  /// malformed. [endedAt] is optional here because the receiver prefers the
  /// authoritative server timestamp of the carrying event over any sender
  /// value.
  static CallOutcomeRecord? fromMap(Object? map) {
    final typedMap = _asMap(map);
    if (typedMap == null) return null;

    final callId = _readRequiredNonEmptyString(typedMap, _callIdKey);
    if (callId == null) return null;

    final outcome = _outcomeFromName(typedMap[_outcomeKey]);
    if (outcome == null) return null;

    final answered = _readRequiredBool(typedMap, _answeredKey);
    if (answered == null) return null;

    return CallOutcomeRecord(
      callId: callId,
      outcome: outcome,
      answered: answered,
      startedAt: _dateFromMillis(typedMap[_startedAtKey]),
      endedAt: _dateFromMillis(typedMap[_endedAtKey]),
    );
  }

  static const _callIdKey = 'call_id';
  static const _outcomeKey = 'outcome';
  static const _answeredKey = 'answered';
  static const _startedAtKey = 'started_at_ms';
  static const _endedAtKey = 'ended_at_ms';

  /// Transport call session ID. Matches CallMetadata.callId on both sides.
  final String callId;

  /// The canonical terminal outcome.
  final CallOutcome outcome;

  /// Whether the call was answered by at least one participant.
  final bool answered;

  /// When the call started. `null` if the call was never answered.
  final DateTime? startedAt;

  /// When the call ended or was terminated.
  final DateTime? endedAt;

  /// Serializes this record into a transport map. [endedAt] is included only
  /// when set; receivers may override it with the carrying event's server
  /// timestamp.
  Map<String, dynamic> toMap() => {
    _callIdKey: callId,
    _outcomeKey: outcome.name,
    _answeredKey: answered,
    if (startedAt != null) _startedAtKey: startedAt!.millisecondsSinceEpoch,
    if (endedAt != null) _endedAtKey: endedAt!.millisecondsSinceEpoch,
  };

  /// Returns a copy with the given fields replaced.
  CallOutcomeRecord copyWith({DateTime? startedAt, DateTime? endedAt}) =>
      CallOutcomeRecord(
        callId: callId,
        outcome: outcome,
        answered: answered,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
      );

  static CallOutcome? _outcomeFromName(Object? value) {
    if (value is! String) return null;
    for (final outcome in CallOutcome.values) {
      if (outcome.name == value) return outcome;
    }
    return null;
  }

  static DateTime? _dateFromMillis(Object? value) {
    if (value is! int) return null;
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
}

Map<Object?, Object?>? _asMap(Object? value) {
  if (value is! Map) return null;
  return value;
}

String? _readRequiredNonEmptyString(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) return null;
  return value;
}

bool? _readRequiredBool(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value is! bool) return null;
  return value;
}
