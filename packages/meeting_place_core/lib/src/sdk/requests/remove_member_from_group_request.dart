/// Parameters for `MeetingPlaceCoreSDK.removeMemberFromGroup`.
class RemoveMemberFromGroupRequest {
  const RemoveMemberFromGroupRequest({
    required this.groupId,
    required this.memberDid,
  });

  /// Identifier of the group to remove the member from.
  final String groupId;

  /// DID of the member to remove.
  final String memberDid;
}
