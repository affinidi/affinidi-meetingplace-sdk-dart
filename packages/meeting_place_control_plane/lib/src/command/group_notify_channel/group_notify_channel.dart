import '../../core/command/command.dart';
import 'notify_group_channel_result.dart';

/// Model that represents the request sent for the [GroupNotifyChannelRequest]
/// operation.
class GroupNotifyChannelRequest
    extends DiscoveryCommand<NotifyGroupChannelResult> {
  /// Creates a new instance of [GroupNotifyChannelRequest].
  GroupNotifyChannelRequest({
    required this.groupId,
    required this.type,
    this.memberDid,
  });

  /// The unique identifier of the group chat to notify.
  final String groupId;

  /// The notification type to send to group members.
  final String type;

  /// When set, notify only this single group member instead of all members.
  final String? memberDid;
}
