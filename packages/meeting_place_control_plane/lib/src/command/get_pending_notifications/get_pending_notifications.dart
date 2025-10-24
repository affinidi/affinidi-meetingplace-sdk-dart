import '../../core/command/command.dart';
import '../../core/device/device.dart';
import 'get_pending_notifications_output.dart';

/// Model that represents the request sent for the [GetPendingNotificationsCommand]
/// operation.
class GetPendingNotificationsCommand
    extends DiscoveryCommand<GetPendingNotificationsCommandOutput> {
  /// Creates a new instance of [GetPendingNotificationsCommand].
  GetPendingNotificationsCommand({required this.device});

  final Device device;
}
