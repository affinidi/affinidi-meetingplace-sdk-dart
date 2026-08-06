/// Group participation summary for a call chat item.
///
/// Present only for group calls. A `null` participation block on
/// call metadata means a 1:1 call, for which the existing render rules apply
/// unchanged.
class CallParticipation {
  CallParticipation({
    required int participantCount,
    required this.didSelfJoin,
    required this.selfLeftBeforeEnd,
    this.initiatorDid,
    List<String> participantDids = const [],
  }) : participantCount = _validateParticipantCount(participantCount),
       participantDids = List.unmodifiable(participantDids);

  /// Reads a participation block from a nested metadata [map], or `null` when
  /// the map is absent or malformed.
  static CallParticipation? fromMap(Object? map) {
    final typedMap = _asMap(map);
    if (typedMap == null) return null;

    final count = _readRequiredNonNegativeInt(typedMap, _participantCountKey);
    if (count == null) return null;

    final didSelfJoin = _readRequiredBool(typedMap, _didSelfJoinKey);
    if (didSelfJoin == null) return null;

    final selfLeftBeforeEnd = _readRequiredBool(
      typedMap,
      _selfLeftBeforeEndKey,
    );
    if (selfLeftBeforeEnd == null) return null;

    final initiatorDid = _readOptionalString(typedMap, _initiatorDidKey);
    if (typedMap[_initiatorDidKey] != null && initiatorDid == null) {
      return null;
    }

    // Absent entirely (records persisted before this field existed) reads as
    // an empty list rather than failing the whole block. Invalid individual
    // entries are dropped rather than failing the whole block too (see
    // _readParticipantDids) so a single bad entry cannot force a group call
    // to lose its participation summary.
    final participantDids = _readParticipantDids(typedMap, _participantDidsKey);
    if (typedMap[_participantDidsKey] != null && participantDids == null) {
      return null;
    }

    return CallParticipation(
      participantCount: count,
      didSelfJoin: didSelfJoin,
      selfLeftBeforeEnd: selfLeftBeforeEnd,
      initiatorDid: initiatorDid,
      participantDids: participantDids!,
    );
  }

  static const _participantCountKey = 'participant_count';
  static const _didSelfJoinKey = 'did_self_join';
  static const _selfLeftBeforeEndKey = 'self_left_before_end';
  static const _initiatorDidKey = 'initiator_did';
  static const _participantDidsKey = 'participant_dids';

  /// Distinct peers in the call, excluding the local party. Drives the "n
  /// joined" wording.
  ///
  /// Kept independently of [participantDids] rather than derived from its
  /// length: a peer's DID may be unresolved at the moment the call record is
  /// finalized (see [participantDids]), in which case the count can still
  /// reflect the true number of distinct peers while the name list only
  /// carries the subset that were identifiable.
  final int participantCount;

  /// Whether the local party joined the call.
  final bool didSelfJoin;

  /// Whether the local party left while other peers were still in the call.
  final bool selfLeftBeforeEnd;

  /// DID of the party that started the call, when known.
  final String? initiatorDid;

  /// Permanent channel DIDs of the peers known to have participated in the
  /// call, excluding the local party.
  ///
  /// May be empty even when [participantCount] is positive: a peer's DID can
  /// be unresolved at finalization time, and records persisted before this
  /// field existed carry no DIDs at all. Unmodifiable.
  ///
  /// When deserialized via [fromMap], each entry is validated as a
  /// DID-shaped string within a length bound (see [_readParticipantDids]);
  /// invalid or oversized entries are dropped rather than failing the whole
  /// block, and at most [_maxParticipantDidCount] entries are kept. This way
  /// external metadata cannot spoof arbitrary identity strings, exhaust
  /// client resources, or force a group call to lose its participation
  /// summary over one bad entry.
  final List<String> participantDids;

  /// Serializes this participation block into a nested metadata map.
  Map<String, dynamic> toMap() => {
    _participantCountKey: participantCount,
    _didSelfJoinKey: didSelfJoin,
    _selfLeftBeforeEndKey: selfLeftBeforeEnd,
    if (initiatorDid != null) _initiatorDidKey: initiatorDid,
    if (participantDids.isNotEmpty) _participantDidsKey: participantDids,
  };

  /// Returns a copy with the given fields replaced.
  CallParticipation copyWith({
    int? participantCount,
    bool? didSelfJoin,
    bool? selfLeftBeforeEnd,
    String? initiatorDid,
    List<String>? participantDids,
  }) => CallParticipation(
    participantCount: participantCount ?? this.participantCount,
    didSelfJoin: didSelfJoin ?? this.didSelfJoin,
    selfLeftBeforeEnd: selfLeftBeforeEnd ?? this.selfLeftBeforeEnd,
    initiatorDid: initiatorDid ?? this.initiatorDid,
    participantDids: participantDids ?? this.participantDids,
  );

  static int _validateParticipantCount(int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'participantCount', 'must be >= 0');
    }
    return count;
  }
}

Map<Object?, Object?>? _asMap(Object? value) {
  if (value is! Map) return null;
  return value;
}

String? _readOptionalString(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! String) return null;
  return value;
}

int? _readRequiredNonNegativeInt(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value is! int || value < 0) return null;
  return value;
}

bool? _readRequiredBool(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value is! bool) return null;
  return value;
}

/// Upper bound on the number of participant DIDs accepted from external
/// (Matrix event) metadata, so a maliciously oversized list cannot exhaust
/// client memory/CPU during parsing.
const _maxParticipantDidCount = 256;

/// Upper bound on the length of a single participant DID string accepted
/// from external metadata, for the same reason as [_maxParticipantDidCount].
const _maxParticipantDidLength = 512;

/// Minimal DID URI shape check (`did:<method>:<method-specific-id>`), per
/// the W3C DID Core ABNF. Deliberately permissive on the method-specific-id
/// charset: this rejects obviously spoofed/malformed input, not a full
/// per-method conformance check.
final RegExp _participantDidPattern = RegExp(
  r'^did:[a-z0-9]+:[A-Za-z0-9._:%-]+$',
);

/// Reads the `participant_dids` list, or `null` when [key]'s value is
/// present but not a `List` at all (a structurally wrong payload, same
/// contract as every other field in this class: fail the whole block).
///
/// Once it's known to be a list, bad individual entries (wrong type,
/// oversized, not DID-shaped) are dropped rather than failing the whole
/// block: [CallParticipation.participantCount] must stay independent of how
/// many DIDs resolve, and a single attacker-controlled entry from Matrix
/// event metadata must not be able to downgrade a group call's rendering.
/// At most [_maxParticipantDidCount] raw entries are examined, bounding
/// parse cost regardless of payload size.
List<String>? _readParticipantDids(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value == null) return const [];
  if (value is! List) return null;
  final result = <String>[];
  for (final element in value.take(_maxParticipantDidCount)) {
    if (element is! String) continue;
    if (element.length > _maxParticipantDidLength) continue;
    if (!_participantDidPattern.hasMatch(element)) continue;
    result.add(element);
  }
  return result;
}
