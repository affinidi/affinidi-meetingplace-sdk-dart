import '../../../meeting_place_control_plane.dart'
    show DeletePendingNotificationsCommand;
import '../../core/command/command.dart';
import '../command.dart' show DeletePendingNotificationsCommand;
import '../delete_pending_notifications/delete_pending_notifications.dart'
    show DeletePendingNotificationsCommand;
import 'deregister_notification_output.dart';

/// Model that represents the request sent for the
/// [DeregisterNotificationCommand] operation.
class DeregisterNotificationCommand
    extends DiscoveryCommand<DeregisterNotificationOutput> {
  /// Creates a new instance of [DeletePendingNotificationsCommand].
  DeregisterNotificationCommand({required this.notificationToken});
  final String notificationToken;
}
