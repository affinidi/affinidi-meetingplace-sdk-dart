import '../../core/exception/control_plane_exception.dart';

/// RegisterNotificationExceptionCodes enum definitions.
enum RegisterNotificationExceptionCodes {
  generic('discovery_register_notification_generic');

  const RegisterNotificationExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Register Notification command/operation.
class RegisterNotificationException implements ControlPlaneException {
  RegisterNotificationException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [RegisterNotificationException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory RegisterNotificationException.generic({Object? innerException}) {
    return RegisterNotificationException._(
      message: 'Register notification exception: ${innerException.toString()}.',
      code: RegisterNotificationExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final RegisterNotificationExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
