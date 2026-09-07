import '../../core/command/command.dart';
import 'group_deregister_member_output.dart';

/// Model that represents the request sent for the
/// [GroupDeregisterMemberRequest]
/// operation.
class GroupDeregisterMemberRequest
    extends DiscoveryCommand<GroupDeregisterMemberCommandOutput> {
  /// Creates a new instance of [GroupDeregisterMemberRequest].
  GroupDeregisterMemberRequest({required this.groupId, required this.memberId});

  /// The identifier of the group to remove the member from.
  final String groupId;

  /// The DID of the member to deregister from the group.
  final String memberId;
}
