import '../../core/command/command.dart';
import '../../core/device/device_platform.dart';
import 'register_device_result.dart';

/// Model that represents the request sent for the [RegisterDeviceRequest]
/// operation.
class RegisterDeviceRequest extends DiscoveryCommand<RegisterDeviceResult> {
  /// Creates a new instance of [RegisterDeviceRequest].
  RegisterDeviceRequest({
    required this.deviceToken,
    required this.platformType,
  });

  /// The device's push notification token.
  final String deviceToken;

  /// The platform the device runs on.
  final PlatformType platformType;
}
