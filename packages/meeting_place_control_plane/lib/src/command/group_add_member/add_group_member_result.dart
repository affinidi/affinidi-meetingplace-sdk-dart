import 'group_add_member_request.dart' show GroupAddMemberRequest;

/// The result returned when a member is added to a group.
/// Model that represents the output data returned from a successful execution
/// of [GroupAddMemberRequest] operation.
class AddGroupMemberResult {
  /// Creates a new instance of [AddGroupMemberResult].
  AddGroupMemberResult({required this.success});

  /// Whether the member was successfully added to the group.
  final bool success;
}
