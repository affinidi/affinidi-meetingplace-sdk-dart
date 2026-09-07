import '../../core/event/discovery_event.dart';
import 'get_pending_notifications.dart' show GetPendingNotificationsCommand;

/// Model that represents the output data returned from a successful execution
/// of [GetPendingNotificationsCommand] operation.
class GetPendingNotificationsCommandOutput {
  /// Creates a new instance of [GetPendingNotificationsCommandOutput].
  GetPendingNotificationsCommandOutput({required this.events});
  final List<ControlPlaneEvent> events;
}
