import '../../control_plane_sdk_error_code.dart';

abstract interface class ControlPlaneException implements Exception {
  String get message;
  ControlPlaneSDKErrorCode get code;
  Object? get innerException;
}
