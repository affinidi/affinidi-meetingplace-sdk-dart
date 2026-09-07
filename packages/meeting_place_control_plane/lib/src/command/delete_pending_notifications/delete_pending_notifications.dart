import '../../core/command/command.dart';
import '../../core/device/device.dart';
import 'delete_pending_notifications_output.dart';

/// Model that represents the request sent for the
/// [DeletePendingNotificationsRequest]
/// operation.
class DeletePendingNotificationsRequest
    extends DiscoveryCommand<DeletePendingNotificationsCommandOutput> {
  /// Creates a new instance of [DeletePendingNotificationsRequest].
  DeletePendingNotificationsRequest({
    required this.device,
    required this.notificationIds,
  });

  /// The device the pending notifications belong to.
  final Device device;

  /// The identifiers of the pending notifications to delete.
  final List<String> notificationIds;
}
