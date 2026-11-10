/// Parameters for `MeetingPlaceCoreSDK.setGroupMembersCanPost`.
class SetGroupMembersCanPostRequest {
  /// Creates a [SetGroupMembersCanPostRequest].
  const SetGroupMembersCanPostRequest({
    required this.groupId,
    required this.membersCanPost,
  });

  /// Identifier of the group.
  final String groupId;

  /// Whether every member may post in the group's chat from now on, rather
  /// than only its owner and moderators.
  final bool membersCanPost;
}
