import 'register_device_request.dart' show RegisterDeviceRequest;

/// The result returned when a device is registered.
/// Model that represents the output data returned from a successful execution
/// of [RegisterDeviceRequest] operation.
class RegisterDeviceResult {
  /// Creates a new instance of [RegisterDeviceResult].
  RegisterDeviceResult({required this.success});

  /// Whether the device was registered successfully.
  final bool success;
}
