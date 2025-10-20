import '../../core/exception/control_plane_exception.dart';

/// GetPendingNotificationsExceptionCodes enum definitions.
enum GetPendingNotificationsExceptionCodes {
  generic('discovery_get_pending_notifications_generic'),
  notificationPayloadError(
    'discovery_get_pending_notifications_notification_payload_error',
  );

  const GetPendingNotificationsExceptionCodes(this.code);
  final String code;
}

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
      code: GetPendingNotificationsExceptionCodes.notificationPayloadError,
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
      code: GetPendingNotificationsExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final GetPendingNotificationsExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
