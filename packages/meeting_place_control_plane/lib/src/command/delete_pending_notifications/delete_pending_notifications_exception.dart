import '../../core/exception/control_plane_exception.dart';

/// DeletePendingNotificationsExceptionCodes enum definitions.
enum DeletePendingNotificationsExceptionCodes {
  generic('discovery_delete_pending_notifications_generic'),
  deletionFailedError(
    'discovery_delete_pending_notifications_deletion_failed_error',
  );

  const DeletePendingNotificationsExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Delete Pending Notifications command/operation.
class DeletePendingNotificationsException implements ControlPlaneException {
  DeletePendingNotificationsException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `deletionFailedError` [DeletePendingNotificationsException] instance.
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
      message:
          '''Delete pending notifications failed: ${innerException.toString()}, deleted notification ids: ${deletedNotificationIds.join(',')}''',
      code: DeletePendingNotificationsExceptionCodes.deletionFailedError,
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
      code: DeletePendingNotificationsExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final DeletePendingNotificationsExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
