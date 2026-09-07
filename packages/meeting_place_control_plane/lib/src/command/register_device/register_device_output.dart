import 'register_device.dart' show RegisterDeviceCommand;

/// Model that represents the output data returned from a successful execution
/// of [RegisterDeviceCommand] operation.
class RegisterDeviceCommandOutput {
  /// Creates a new instance of [RegisterDeviceCommandOutput].
  RegisterDeviceCommandOutput({required this.success});
  final bool success;
}
