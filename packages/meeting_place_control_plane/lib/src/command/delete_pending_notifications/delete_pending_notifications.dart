import '../../core/command/command.dart';
import '../../core/device/device.dart';
import 'delete_pending_notifications_output.dart';

/// Model that represents the request sent for the [DeletePendingNotificationsCommand]
/// operation.
class DeletePendingNotificationsCommand
    extends DiscoveryCommand<DeletePendingNotificationsCommandOutput> {
  /// Creates a new instance of [DeletePendingNotificationsCommand].
  DeletePendingNotificationsCommand({
    required this.device,
    required this.notificationIds,
  });
  final Device device;
  final List<String> notificationIds;
}
