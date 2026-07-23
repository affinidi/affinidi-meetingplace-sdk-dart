import '../../core/command/command.dart';
import 'group_notify_channel_output.dart';

/// Model that represents the request sent for the [GroupNotifyChannelCommand]
/// operation.
class GroupNotifyChannelCommand
    extends DiscoveryCommand<GroupNotifyChannelCommandOutput> {
  /// Creates a new instance of [GroupNotifyChannelCommand].
  GroupNotifyChannelCommand({
    required this.offerLink,
    required this.groupDid,
    required this.type,
    this.memberDid,
  });

  /// The Offer link associated with the group chat.
  final String offerLink;

  /// The channel DID for the group chat.
  final String groupDid;

  /// The notification type to send to group members.
  final String type;

  /// When set, notify only this single group member instead of all members.
  final String? memberDid;
}
