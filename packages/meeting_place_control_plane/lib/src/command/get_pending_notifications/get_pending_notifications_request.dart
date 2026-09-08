import '../../core/command/command.dart';
import '../../core/device/device.dart';
import 'get_pending_notifications_result.dart';

/// Model that represents the request sent for the
/// [GetPendingNotificationsRequest]
/// operation.
class GetPendingNotificationsRequest
    extends DiscoveryCommand<GetPendingNotificationsResult> {
  /// Creates a new instance of [GetPendingNotificationsRequest].
  GetPendingNotificationsRequest({required this.device});

  /// The device to fetch pending notifications for.
  final Device device;
}
