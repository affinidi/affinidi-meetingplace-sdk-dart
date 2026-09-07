import 'group_add_member.dart' show GroupAddMemberCommand;

/// Model that represents the output data returned from a successful execution
/// of [GroupAddMemberCommand] operation.
class GroupAddMemberCommandOutput {
  /// Creates a new instance of [GroupAddMemberCommandOutput].
  GroupAddMemberCommandOutput({required this.success});
  final bool success;
}
