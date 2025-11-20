import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to RegisterDevice command/operation.
class RegisterDeviceException implements ControlPlaneException {
  RegisterDeviceException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [RegisterDeviceException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory RegisterDeviceException.generic({Object? innerException}) {
    return RegisterDeviceException._(
      message: 'Register device exception: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.registerDeviceGeneric,
      innerException: innerException,
    );
  }
  @override
  final String message;

  @override
  final ControlPlaneSDKErrorCode code;

  @override
  final Object? innerException;
}
