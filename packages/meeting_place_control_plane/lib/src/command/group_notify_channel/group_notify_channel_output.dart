import 'group_notify_channel.dart' show GroupNotifyChannelCommand;

/// Model that represents the output data returned from a successful execution
/// of [GroupNotifyChannelCommand] operation.
class GroupNotifyChannelCommandOutput {
  /// Creates a new instance of [GroupNotifyChannelCommandOutput].
  GroupNotifyChannelCommandOutput({required this.success});
  final bool success;
}
