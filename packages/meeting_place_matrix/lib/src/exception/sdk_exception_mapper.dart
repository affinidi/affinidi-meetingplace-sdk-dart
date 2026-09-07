import '../matrix_auth_exception.dart';
import '../matrix_service_exception.dart';
import '../meeting_place_matrix_sdk_error_code.dart';
import 'matrix_sdk_exception.dart';

/// Converts any error raised from matrix-specific code into the unified
/// [MeetingPlaceMatrixSDKException], passing an already-unified exception
/// through unchanged, mapping [MatrixAuthException] to a dedicated code, and
/// falling back to [MeetingPlaceMatrixSDKErrorCode.generic] for anything
/// else (including exceptions from other MeetingPlace SDK packages, kept as
/// the inner exception).
MeetingPlaceMatrixSDKException toMatrixSdkException(Object error) {
  if (error is MeetingPlaceMatrixSDKException) return error;
  if (error is MatrixAuthException) {
    return MatrixServiceException(
      message: error.message,
      code: MeetingPlaceMatrixSDKErrorCode.matrixAuthError,
      innerException: error,
    );
  }
  return MatrixServiceException(
    message: error.toString(),
    code: MeetingPlaceMatrixSDKErrorCode.generic,
    innerException: error,
  );
}
