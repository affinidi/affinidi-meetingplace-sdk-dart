import '../../core/exception/control_plane_exception.dart';
import '../../meeting_place_control_plane_sdk_error_code.dart';

class MatrixTokenException implements ControlPlaneException {
  MatrixTokenException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory MatrixTokenException.invalidResponse({
    required String message,
    Object? innerException,
  }) {
    return MatrixTokenException._(
      message: message,
      code: MeetingPlaceControlPlaneSDKErrorCode.matrixTokenInvalidResponse,
      innerException: innerException,
    );
  }

  factory MatrixTokenException.generic({
    required String message,
    Object? innerException,
  }) {
    return MatrixTokenException._(
      message: message,
      code: MeetingPlaceControlPlaneSDKErrorCode.matrixTokenGeneric,
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
