import 'package:meta/meta.dart';

/// A single participant currently present in an ongoing group call, derived
/// from a non-expired MatrixRTC `m.call.member` state event.
@immutable
class OngoingGroupCallParticipant {
  const OngoingGroupCallParticipant({
    required this.matrixUserId,
    required this.deviceId,
    required this.isSelf,
    this.did,
  });

  /// The Matrix user ID of the participant's membership.
  final String matrixUserId;

  /// The Matrix device ID of the participant's membership.
  final String deviceId;

  /// Whether this membership belongs to the local user (any of their devices).
  final bool isSelf;

  /// The resolved permanent channel DID of the participant, when it could be
  /// matched against the channel's known members. `null` when the membership
  /// could not be mapped to a known DID.
  final String? did;

  @override
  bool operator ==(Object other) =>
      other is OngoingGroupCallParticipant &&
      other.matrixUserId == matrixUserId &&
      other.deviceId == deviceId &&
      other.isSelf == isSelf &&
      other.did == did;

  @override
  int get hashCode => Object.hash(matrixUserId, deviceId, isSelf, did);

  @override
  String toString() =>
      'OngoingGroupCallParticipant(matrixUserId: $matrixUserId, '
      'deviceId: $deviceId, isSelf: $isSelf, did: $did)';
}

/// Snapshot of an in-progress group call in a channel's Matrix room, observed
/// without joining the call.
///
/// Built from the non-expired MatrixRTC call memberships currently published
/// in the room. Consumers use it to render an "ongoing call" affordance (for
/// example a join banner) for a call the local user has not joined.
@immutable
class OngoingGroupCall {
  const OngoingGroupCall({required this.callId, required this.participants});

  /// The MatrixRTC call ID shared by the memberships in this call.
  final String callId;

  /// The participants currently present in the call.
  final List<OngoingGroupCallParticipant> participants;

  /// The number of participants currently present in the call.
  int get participantCount => participants.length;

  /// The participants excluding the local user's own memberships.
  List<OngoingGroupCallParticipant> get remoteParticipants =>
      participants.where((p) => !p.isSelf).toList(growable: false);

  @override
  bool operator ==(Object other) =>
      other is OngoingGroupCall &&
      other.callId == callId &&
      _listEquals(other.participants, participants);

  @override
  int get hashCode => Object.hash(callId, Object.hashAll(participants));

  @override
  String toString() =>
      'OngoingGroupCall(callId: $callId, participants: $participants)';
}

bool _listEquals(
  List<OngoingGroupCallParticipant> a,
  List<OngoingGroupCallParticipant> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
