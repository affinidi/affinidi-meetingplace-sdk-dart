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
    // an empty list rather than failing the whole block.
    final participantDids = _readOptionalStringList(
      typedMap,
      _participantDidsKey,
    );
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

List<String>? _readOptionalStringList(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value == null) return const [];
  if (value is! List) return null;
  final result = <String>[];
  for (final element in value) {
    if (element is! String) return null;
    result.add(element);
  }
  return result;
}
