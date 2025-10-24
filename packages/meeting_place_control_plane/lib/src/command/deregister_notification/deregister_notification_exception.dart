import '../../core/exception/control_plane_exception.dart';
import '../../control_plane_sdk_error_code.dart';

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
      code: ControlPlaneSDKErrorCode.deregisterNotificationGeneric,
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
