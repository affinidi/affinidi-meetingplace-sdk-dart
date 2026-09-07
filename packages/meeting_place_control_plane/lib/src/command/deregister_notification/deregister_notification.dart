import '../../core/command/command.dart';
import 'deregister_notification_output.dart';

/// Model that represents the request sent for the
/// [DeregisterNotificationCommand]
/// operation.
class DeregisterNotificationCommand
    extends DiscoveryCommand<DeregisterNotificationOutput> {
  /// Creates a new instance of [DeregisterNotificationCommand].
  DeregisterNotificationCommand({required this.notificationToken});

  /// The push notification token to deregister.
  final String notificationToken;
}
