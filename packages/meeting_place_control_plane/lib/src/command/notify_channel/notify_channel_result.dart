import 'notify_channel_request.dart' show NotifyChannelRequest;

/// The result returned when a channel notification is sent.
/// Model that represents the output data returned from a successful execution
/// of [NotifyChannelRequest] operation.
class NotifyChannelResult {
  /// Creates a new instance of [NotifyChannelResult].
  NotifyChannelResult({required this.success});

  /// Whether the channel notification was sent successfully.
  final bool success;
}
