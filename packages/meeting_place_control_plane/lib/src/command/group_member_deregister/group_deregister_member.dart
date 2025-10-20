import '../../core/command/command.dart';
import 'group_deregister_member_output.dart';

/// Model that represents the request sent for the [GroupDeregisterMemberCommand]
/// operation.
class GroupDeregisterMemberCommand
    extends DiscoveryCommand<GroupDeregisterMemberCommandOutput> {
  /// Creates a new instance of [GroupDeregisterMemberCommand].
  GroupDeregisterMemberCommand({
    required this.groupId,
    required this.memberId,
    required this.messageBase64,
  });
  final String groupId;
  final String memberId;
  final String messageBase64;
}
