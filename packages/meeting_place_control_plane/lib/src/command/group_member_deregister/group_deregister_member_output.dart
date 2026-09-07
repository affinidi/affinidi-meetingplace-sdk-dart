import 'group_deregister_member.dart' show GroupDeregisterMemberCommand;

/// Model that represents the output data returned from a successful execution
/// of [GroupDeregisterMemberCommand] operation.
class GroupDeregisterMemberCommandOutput {
  /// Creates a new instance of [GroupDeregisterMemberCommandOutput].
  GroupDeregisterMemberCommandOutput({required this.success});
  final bool success;
}
