import '../../core/exception/control_plane_exception.dart';
import '../../control_plane_sdk_error_code.dart';

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to get pending notifications command/operation.
class GetPendingNotificationsException implements ControlPlaneException {
  GetPendingNotificationsException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `notificationPayloadError` [GetPendingNotificationsException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory GetPendingNotificationsException.notificationPayloadError({
    Object? innerException,
  }) {
    return GetPendingNotificationsException._(
      message:
          'Get pending notifications exception: Invalid or empty notification payload.',
      code: ControlPlaneSDKErrorCode
          .getPendingNotificationsNotificationPayloadError,
      innerException: innerException,
    );
  }

  /// Creates a `generic` [GetPendingNotificationsException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory GetPendingNotificationsException.generic({Object? innerException}) {
    return GetPendingNotificationsException._(
      message:
          'Get pending notifications exception: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.getPendingNotificationsGeneric,
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
