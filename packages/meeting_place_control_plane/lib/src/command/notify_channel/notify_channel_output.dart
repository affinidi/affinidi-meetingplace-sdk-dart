import 'notify_channel.dart' show NotifyChannelCommand;

/// Model that represents the output data returned from a successful execution
/// of [NotifyChannelCommand] operation.
class NotifyChannelCommandOutput {
  /// Creates a new instance of [NotifyChannelCommandOutput].
  NotifyChannelCommandOutput({required this.success});
  final bool success;
}
