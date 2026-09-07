import 'group_add_member.dart' show GroupAddMemberCommand;

/// The result returned when a member is added to a group.
typedef AddGroupMemberResult = GroupAddMemberCommandOutput;

/// Model that represents the output data returned from a successful execution
/// of [GroupAddMemberCommand] operation.
class GroupAddMemberCommandOutput {
  /// Creates a new instance of [GroupAddMemberCommandOutput].
  GroupAddMemberCommandOutput({required this.success});

  /// Whether the member was successfully added to the group.
  final bool success;
}
