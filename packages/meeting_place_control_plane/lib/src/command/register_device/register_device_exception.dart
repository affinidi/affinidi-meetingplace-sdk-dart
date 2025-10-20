import '../../core/exception/control_plane_exception.dart';

/// RegisterDeviceExceptionCodes enum definitions.
enum RegisterDeviceExceptionCodes {
  generic('discovery_register_device_generic');

  const RegisterDeviceExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Register Device command/operation.
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
      code: RegisterDeviceExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final RegisterDeviceExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
