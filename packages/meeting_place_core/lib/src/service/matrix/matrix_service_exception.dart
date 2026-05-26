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
