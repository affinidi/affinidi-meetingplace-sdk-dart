import 'register_device.dart' show RegisterDeviceRequest;

/// The result returned when a device is registered.
typedef RegisterDeviceResult = RegisterDeviceCommandOutput;

/// Model that represents the output data returned from a successful execution
/// of [RegisterDeviceRequest] operation.
class RegisterDeviceCommandOutput {
  /// Creates a new instance of [RegisterDeviceCommandOutput].
  RegisterDeviceCommandOutput({required this.success});

  /// Whether the device was registered successfully.
  final bool success;
}
