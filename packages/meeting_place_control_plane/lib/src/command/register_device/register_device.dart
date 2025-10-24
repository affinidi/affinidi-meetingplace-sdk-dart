import '../../core/device/device_platform.dart';
import '../../core/command/command.dart';
import 'register_device_output.dart';

/// Model that represents the request sent for the [RegisterDeviceCommand]
/// operation.
class RegisterDeviceCommand
    extends DiscoveryCommand<RegisterDeviceCommandOutput> {
  /// Creates a new instance of [RegisterDeviceCommand].
  RegisterDeviceCommand({
    required this.deviceToken,
    required this.platformType,
  });
  final String deviceToken;
  final PlatformType platformType;
}
