import '../../core/exception/control_plane_exception.dart';
import '../../meeting_place_control_plane_sdk_error_code.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing
/// specific exceptions related to deregister notifications command/operation.
class DeregisterNotificationsException implements ControlPlaneException {
  DeregisterNotificationsException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [DeregisterNotificationsException] instance.
  ///
  /// This constructor provides the specific message and error code for the
  /// operation, wrapping the given [innerException].
  factory DeregisterNotificationsException.generic({Object? innerException}) {
    return DeregisterNotificationsException._(
      message: 'Deregister notification failed: ${innerException.toString()}.',
      code: MeetingPlaceControlPlaneSDKErrorCode.deregisterNotificationGeneric,
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
