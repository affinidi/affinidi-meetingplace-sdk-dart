import 'group_deregister_member_request.dart' show GroupDeregisterMemberRequest;

/// The result returned when a member is deregistered from a group.
/// Model that represents the output data returned from a successful execution
/// of [GroupDeregisterMemberRequest] operation.
class DeregisterGroupMemberResult {
  /// Creates a new instance of [DeregisterGroupMemberResult].
  DeregisterGroupMemberResult({required this.success});

  /// Whether the member was successfully deregistered from the group.
  final bool success;
}
