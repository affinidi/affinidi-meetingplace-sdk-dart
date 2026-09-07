import 'group_deregister_member.dart' show GroupDeregisterMemberCommand;

/// The result returned when a member is deregistered from a group.
typedef DeregisterGroupMemberResult = GroupDeregisterMemberCommandOutput;

/// Model that represents the output data returned from a successful execution
/// of [GroupDeregisterMemberCommand] operation.
class GroupDeregisterMemberCommandOutput {
  /// Creates a new instance of [GroupDeregisterMemberCommandOutput].
  GroupDeregisterMemberCommandOutput({required this.success});

  /// Whether the member was successfully deregistered from the group.
  final bool success;
}
