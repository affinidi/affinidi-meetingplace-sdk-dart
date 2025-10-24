import '../../core/command/command.dart';
import 'notify_channel_output.dart';

/// Model that represents the request sent for the [NotifyChannelCommand]
/// operation.
class NotifyChannelCommand
    extends DiscoveryCommand<NotifyChannelCommandOutput> {
  /// Creates a new instance of [NotifyChannelCommand].
  NotifyChannelCommand({
    required this.notificationToken,
    required this.did,
    required this.type,
  });
  final String notificationToken;
  final String did;
  final String type;
}
