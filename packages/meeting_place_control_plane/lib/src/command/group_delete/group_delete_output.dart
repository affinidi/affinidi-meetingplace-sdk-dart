import 'group_delete.dart' show GroupDeleteRequest;

/// The result returned when a group is deleted.
typedef DeleteGroupResult = GroupDeleteCommandOutput;

/// Model that represents the output data returned from a successful execution
/// of [GroupDeleteRequest] operation.
class GroupDeleteCommandOutput {
  /// Creates a new instance of [GroupDeleteCommandOutput].
  GroupDeleteCommandOutput({required this.success});

  /// Whether the group was successfully deleted.
  final bool success;
}
