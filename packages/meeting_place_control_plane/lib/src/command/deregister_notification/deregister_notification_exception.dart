import '../../core/exception/control_plane_exception.dart';

/// DeregisterNotificationsExceptionCodes enum definitions.
enum DeregisterNotificationsExceptionCodes {
  generic('discovery_deregister_notification_generic');

  const DeregisterNotificationsExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to deregister notifications command/operation.
class DeregisterNotificationsException implements ControlPlaneException {
  DeregisterNotificationsException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [DeregisterNotificationsException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory DeregisterNotificationsException.generic({Object? innerException}) {
    return DeregisterNotificationsException._(
      message: 'Deregister notification failed: ${innerException.toString()}.',
      code: DeregisterNotificationsExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final DeregisterNotificationsExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
