/// Parameters for `MeetingPlaceCoreSDK.setGroupModerator`.
class SetGroupModeratorRequest {
  /// Creates a [SetGroupModeratorRequest].
  const SetGroupModeratorRequest({
    required this.groupId,
    required this.memberDid,
    required this.isModerator,
  });

  /// Identifier of the group.
  final String groupId;

  /// DID of the member whose rights change.
  final String memberDid;

  /// Whether the member may moderate the group's chat from now on.
  final bool isModerator;
}
