import 'device_platform.dart';

class Device {
  Device({required this.deviceToken, required this.platformType});
  final String deviceToken;
  final PlatformType platformType;
}
