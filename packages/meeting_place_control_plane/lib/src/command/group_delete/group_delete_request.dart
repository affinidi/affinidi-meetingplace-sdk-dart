import '../../core/command/command.dart';
import 'delete_group_result.dart';

/// Model that represents the request sent for the [GroupDeleteRequest]
/// operation.
class GroupDeleteRequest extends DiscoveryCommand<DeleteGroupResult> {
  /// Creates a new instance of [GroupDeleteRequest].
  GroupDeleteRequest({required this.groupId});

  /// The identifier of the group to delete.
  final String groupId;
}
