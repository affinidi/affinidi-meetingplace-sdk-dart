import '../../core/exception/control_plane_exception.dart';
import '../../meeting_place_control_plane_sdk_error_code.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing
/// specific exceptions related to get OOB command/operation.
class GetOobException implements ControlPlaneException {
  GetOobException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `oobNotFound` [GetOobException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory GetOobException.oobNotFound({Object? innerException}) {
    return GetOobException._(
      message: 'Get OOB exception: OOB not found.',
      code: MeetingPlaceControlPlaneSDKErrorCode.oobNotFound,
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
