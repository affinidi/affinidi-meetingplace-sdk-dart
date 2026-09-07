import '../../core/command/command.dart';
import 'deregister_notification_result.dart';

/// Model that represents the request sent for the
/// [DeregisterNotificationRequest]
/// operation.
class DeregisterNotificationRequest
    extends DiscoveryCommand<DeregisterNotificationResult> {
  /// Creates a new instance of [DeregisterNotificationRequest].
  DeregisterNotificationRequest({required this.notificationToken});

  /// The push notification token to deregister.
  final String notificationToken;
}
