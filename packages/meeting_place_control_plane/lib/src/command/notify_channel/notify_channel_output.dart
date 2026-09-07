import 'notify_channel.dart' show NotifyChannelRequest;

/// The result returned when a channel notification is sent.
typedef NotifyChannelResult = NotifyChannelCommandOutput;

/// Model that represents the output data returned from a successful execution
/// of [NotifyChannelRequest] operation.
class NotifyChannelCommandOutput {
  /// Creates a new instance of [NotifyChannelCommandOutput].
  NotifyChannelCommandOutput({required this.success});

  /// Whether the channel notification was sent successfully.
  final bool success;
}
