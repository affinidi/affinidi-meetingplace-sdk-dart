import '../../exception/sdk_exception.dart';
import '../../meeting_place_core_sdk_error_code.dart';

class MatrixServiceException implements SDKException {
  factory MatrixServiceException.loginFailed({Object? innerException}) {
    return MatrixServiceException(
      message: 'Matrix login failed',
      code: MeetingPlaceCoreSDKErrorCode.matrixLoginFailed,
      innerException: innerException,
    );
  }

  factory MatrixServiceException.encryptionNotEnabled({
    Object? innerException,
  }) {
    return MatrixServiceException(
      message:
          'Matrix client encryption is not enabled; cannot create encrypted '
          'room. Ensure vodozemac initialized successfully before login.',
      code: MeetingPlaceCoreSDKErrorCode.matrixEncryptionNotEnabled,
      innerException: innerException,
    );
  }

  factory MatrixServiceException.missingUserId() {
    return MatrixServiceException(
      message:
          'Matrix client has no userID after session establishment; '
          'this should not happen.',
      code: MeetingPlaceCoreSDKErrorCode.matrixMissingUserId,
    );
  }

  MatrixServiceException({
    required this.message,
    required this.code,
    this.innerException,
  });

  @override
  final String message;

  @override
  final MeetingPlaceCoreSDKErrorCode code;

  @override
  final Object? innerException;
}
