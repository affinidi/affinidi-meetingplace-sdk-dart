import '../../core/exception/control_plane_exception.dart';
import '../../meeting_place_control_plane_sdk_error_code.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing
/// specific exceptions related to Delete Pending Notifications
/// command/operation.
class DeletePendingNotificationsException implements ControlPlaneException {
  DeletePendingNotificationsException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `deletionFailedError` [DeletePendingNotificationsException]
  /// instance.
  ///
  /// This constructor provides the specific message and error code for the
  /// operation, using the [deletedNotificationIds] that were successfully
  /// deleted before the failure and wrapping the given [innerException].
  factory DeletePendingNotificationsException.deletionFailedError({
    required List<String> deletedNotificationIds,
    Object? innerException,
  }) {
    return DeletePendingNotificationsException._(
      message:
          '''Delete pending notifications failed: ${innerException.toString()}, deleted notification ids: ${deletedNotificationIds.join(',')}''',
      code: MeetingPlaceControlPlaneSDKErrorCode
          .deletePendingNotificationsDeletionFailedError,
      innerException: innerException,
    );
  }

  /// Creates a `generic` [DeletePendingNotificationsException] instance.
  ///
  /// This constructor provides the specific message and error code for the
  /// operation, wrapping the given [innerException].
  factory DeletePendingNotificationsException.generic({
    Object? innerException,
  }) {
    return DeletePendingNotificationsException._(
      message: 'Authentication failed: ${innerException.toString()}.',
      code: MeetingPlaceControlPlaneSDKErrorCode
          .deletePendingNotificationsGeneric,
      innerException: innerException,
    );
  }
  @override
  final String message;

  @override
  final MeetingPlaceControlPlaneSDKErrorCode code;

  @override
  final Object? innerException;
}
