import '../../core/command/command.dart';
import 'deregister_notification_output.dart';

/// Model that represents the request sent for the [DeregisterNotificationCommand]
/// operation.
class DeregisterNotificationCommand
    extends DiscoveryCommand<DeregisterNotificationOutput> {
  /// Creates a new instance of [DeletePendingNotificationsCommand].
  DeregisterNotificationCommand({required this.notificationToken});
  final String notificationToken;
}
