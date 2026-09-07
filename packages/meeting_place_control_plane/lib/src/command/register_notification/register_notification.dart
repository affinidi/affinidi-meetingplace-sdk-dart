import '../../core/command/command.dart';
import '../../core/device/device.dart';
import 'register_notification_output.dart';

/// Model that represents the request sent for the [RegisterNotificationRequest]
/// operation.
class RegisterNotificationRequest
    extends DiscoveryCommand<RegisterNotificationOutput> {
  /// Creates a new instance of [RegisterNotificationRequest].
  RegisterNotificationRequest({
    required this.myDid,
    required this.theirDid,
    required this.device,
  });

  /// The DID of the local party registering for notifications.
  final String myDid;

  /// The DID of the remote party the notification registration is scoped to.
  final String theirDid;

  /// The device to register for push notifications.
  final Device device;
}
