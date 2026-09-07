import 'group_notify_channel.dart' show GroupNotifyChannelCommand;

/// The result returned when a group channel is notified.
typedef NotifyGroupChannelResult = GroupNotifyChannelCommandOutput;

/// Model that represents the output data returned from a successful execution
/// of [GroupNotifyChannelCommand] operation.
class GroupNotifyChannelCommandOutput {
  /// Creates a new instance of [GroupNotifyChannelCommandOutput].
  GroupNotifyChannelCommandOutput({required this.success});

  /// Whether the group notification was sent successfully.
  final bool success;
}
