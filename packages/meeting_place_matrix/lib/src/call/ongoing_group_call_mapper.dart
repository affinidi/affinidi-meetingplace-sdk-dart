import 'package:matrix/matrix.dart' as matrix;

import '../entity/ongoing_group_call.dart';
import '../matrix_user_id_binding.dart';

/// Builds an [OngoingGroupCall] from the room's non-expired MatrixRTC call
/// memberships.
///
/// A room can briefly carry memberships for more than one call generation (for
/// example while a device rejoins), so this groups [memberships] by callId and
/// reports a single call: the one with the most current members, breaking ties
/// by the lexicographically smallest callId for stable output. Participant
/// order follows the input order, which the caller sorts deterministically.
///
/// Each membership's [matrix.CallMembership.userId] is matched back to a DID in
/// [candidateDids] using [serverName]; unmatched memberships keep a `null` DID
/// but still count. A membership is marked self when its DID equals
/// [ownChannelDid]. Returns `null` when [memberships] is empty.
OngoingGroupCall? buildOngoingGroupCall({
  required List<matrix.CallMembership> memberships,
  required String ownChannelDid,
  required String serverName,
  required Set<String> candidateDids,
}) {
  if (memberships.isEmpty) return null;

  final byCallId = <String, List<matrix.CallMembership>>{};
  for (final membership in memberships) {
    (byCallId[membership.callId] ??= <matrix.CallMembership>[]).add(membership);
  }

  final selectedCallId = byCallId.keys.reduce((a, b) {
    final countA = byCallId[a]!.length;
    final countB = byCallId[b]!.length;
    if (countA != countB) return countB > countA ? b : a;
    return b.compareTo(a) < 0 ? b : a;
  });

  final participants = byCallId[selectedCallId]!
      .map((membership) {
        final did = resolveSenderDidFromCandidates(
          matrixUserId: membership.userId,
          serverName: serverName,
          candidateDids: candidateDids,
        );
        return OngoingGroupCallParticipant(
          matrixUserId: membership.userId,
          deviceId: membership.deviceId,
          isSelf: did != null && did == ownChannelDid,
          did: did,
        );
      })
      .toList(growable: false);

  return OngoingGroupCall(callId: selectedCallId, participants: participants);
}
