import '../../core/event/discovery_event.dart';
import 'get_pending_notifications.dart' show GetPendingNotificationsCommand;

/// The result returned when pending notifications are fetched.
typedef GetPendingNotificationsResult = GetPendingNotificationsCommandOutput;

/// Model that represents the output data returned from a successful execution
/// of [GetPendingNotificationsCommand] operation.
class GetPendingNotificationsCommandOutput {
  /// Creates a new instance of [GetPendingNotificationsCommandOutput].
  GetPendingNotificationsCommandOutput({required this.events});

  /// The events delivered by the pending notifications.
  final List<ControlPlaneEvent> events;
}
