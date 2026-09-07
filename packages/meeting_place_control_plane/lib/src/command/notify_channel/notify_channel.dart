import '../../core/command/command.dart';
import 'notify_channel_output.dart';

/// Model that represents the request sent for the [NotifyChannelRequest]
/// operation.
class NotifyChannelRequest
    extends DiscoveryCommand<NotifyChannelCommandOutput> {
  /// Creates a new instance of [NotifyChannelRequest].
  NotifyChannelRequest({
    required this.notificationToken,
    required this.did,
    required this.type,
  });

  /// The token identifying the notification channel to notify.
  final String notificationToken;

  /// The DID of the channel to notify.
  final String did;

  /// The notification type to send.
  final String type;
}
