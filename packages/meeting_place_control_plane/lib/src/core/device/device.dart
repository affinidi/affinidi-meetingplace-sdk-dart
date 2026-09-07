import 'device_platform.dart';

/// A device registered with the control plane API to receive
/// notifications.
class Device {
  /// Creates a new instance of [Device].
  Device({required this.deviceToken, required this.platformType});

  /// The token used to deliver notifications to this device.
  final String deviceToken;

  /// The channel through which notifications are delivered to this device.
  final PlatformType platformType;
}
