import '../../core/command/command.dart';
import '../../core/device/device.dart';
import 'register_notification_output.dart';

/// Model that represents the request sent for the [RegisterNotificationCommand]
/// operation.
class RegisterNotificationCommand
    extends DiscoveryCommand<RegisterNotificationOutput> {
  /// Creates a new instance of [RegisterNotificationCommand].
  RegisterNotificationCommand({
    required this.myDid,
    required this.theirDid,
    required this.device,
  });
  final String myDid;
  final String theirDid;
  final Device device;
}
