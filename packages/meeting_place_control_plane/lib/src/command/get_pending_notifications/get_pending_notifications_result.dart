import '../../core/event/discovery_event.dart';
import 'get_pending_notifications_request.dart'
    show GetPendingNotificationsRequest;

/// The result returned when pending notifications are fetched.
/// Model that represents the output data returned from a successful execution
/// of [GetPendingNotificationsRequest] operation.
class GetPendingNotificationsResult {
  /// Creates a new instance of [GetPendingNotificationsResult].
  GetPendingNotificationsResult({required this.events});

  /// The events delivered by the pending notifications.
  final List<ControlPlaneEvent> events;
}
