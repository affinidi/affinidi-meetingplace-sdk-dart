import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

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
      code: ControlPlaneSDKErrorCode.matrixTokenInvalidResponse,
      innerException: innerException,
    );
  }

  factory MatrixTokenException.generic({
    required String message,
    Object? innerException,
  }) {
    return MatrixTokenException._(
      message: message,
      code: ControlPlaneSDKErrorCode.matrixTokenGeneric,
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
