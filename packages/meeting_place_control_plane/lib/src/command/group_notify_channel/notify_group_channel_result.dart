import 'group_notify_channel_request.dart' show GroupNotifyChannelRequest;

/// The result returned when a group channel is notified.
/// Model that represents the output data returned from a successful execution
/// of [GroupNotifyChannelRequest] operation.
class NotifyGroupChannelResult {
  /// Creates a new instance of [NotifyGroupChannelResult].
  NotifyGroupChannelResult({required this.success});

  /// Whether the group notification was sent successfully.
  final bool success;
}
