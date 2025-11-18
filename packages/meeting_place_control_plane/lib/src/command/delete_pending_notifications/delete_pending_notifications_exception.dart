import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to DeletePendingNotifications
/// command/operation.
class DeletePendingNotificationsException implements ControlPlaneException {
  DeletePendingNotificationsException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `deletionFailedError`
  /// [DeletePendingNotificationsException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory DeletePendingNotificationsException.deletionFailedError({
    required List<String> deletedNotificationIds,
    Object? innerException,
  }) {
    return DeletePendingNotificationsException._(
      message: '''Delete pending notifications failed: '''
          '''${innerException.toString()}, '''
          '''deleted notification ids: ${deletedNotificationIds.join(',')}''',
      code: ControlPlaneSDKErrorCode
          .deletePendingNotificationsDeletionFailedError,
      innerException: innerException,
    );
  }

  /// Creates a `generic` [DeletePendingNotificationsException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory DeletePendingNotificationsException.generic({
    Object? innerException,
  }) {
    return DeletePendingNotificationsException._(
      message: 'Authentication failed: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.deletePendingNotificationsGeneric,
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
