import 'group_delete_request.dart' show GroupDeleteRequest;

/// The result returned when a group is deleted.
/// Model that represents the output data returned from a successful execution
/// of [GroupDeleteRequest] operation.
class DeleteGroupResult {
  /// Creates a new instance of [DeleteGroupResult].
  DeleteGroupResult({required this.success});

  /// Whether the group was successfully deleted.
  final bool success;
}
