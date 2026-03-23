import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

class MatrixRegistrationCredentialException implements ControlPlaneException {
  MatrixRegistrationCredentialException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory MatrixRegistrationCredentialException.invalidResponse({
    required String message,
    Object? innerException,
  }) {
    return MatrixRegistrationCredentialException._(
      message: message,
      code:
          ControlPlaneSDKErrorCode.matrixRegistrationCredentialInvalidResponse,
      innerException: innerException,
    );
  }

  factory MatrixRegistrationCredentialException.generic({
    required String message,
    Object? innerException,
  }) {
    return MatrixRegistrationCredentialException._(
      message: message,
      code: ControlPlaneSDKErrorCode.matrixRegistrationCredentialGeneric,
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
