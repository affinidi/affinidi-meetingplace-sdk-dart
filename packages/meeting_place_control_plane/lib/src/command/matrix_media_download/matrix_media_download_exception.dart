import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

class MatrixMediaDownloadException implements ControlPlaneException {
  MatrixMediaDownloadException._({
    required this.message,
    required this.code,
    this.innerException,
    this.retryAfterSeconds,
  });

  factory MatrixMediaDownloadException.invalidResponse({
    required String message,
    Object? innerException,
  }) {
    return MatrixMediaDownloadException._(
      message: message,
      code: ControlPlaneSDKErrorCode.matrixMediaDownloadInvalidResponse,
      innerException: innerException,
    );
  }

  factory MatrixMediaDownloadException.forbidden({Object? innerException}) {
    return MatrixMediaDownloadException._(
      message: 'Matrix media download is forbidden.',
      code: ControlPlaneSDKErrorCode.matrixMediaDownloadForbidden,
      innerException: innerException,
    );
  }

  factory MatrixMediaDownloadException.notFound({Object? innerException}) {
    return MatrixMediaDownloadException._(
      message: 'Matrix media was not found.',
      code: ControlPlaneSDKErrorCode.matrixMediaDownloadNotFound,
      innerException: innerException,
    );
  }

  factory MatrixMediaDownloadException.rateLimited({
    int? retryAfterSeconds,
    Object? innerException,
  }) {
    return MatrixMediaDownloadException._(
      message: 'Matrix media download is rate limited.',
      code: ControlPlaneSDKErrorCode.matrixMediaDownloadRateLimited,
      retryAfterSeconds: retryAfterSeconds,
      innerException: innerException,
    );
  }

  factory MatrixMediaDownloadException.generic({Object? innerException}) {
    return MatrixMediaDownloadException._(
      message: 'Failed to download Matrix media.',
      code: ControlPlaneSDKErrorCode.matrixMediaDownloadGeneric,
      innerException: innerException,
    );
  }

  @override
  final String message;

  @override
  final ControlPlaneSDKErrorCode code;

  @override
  final Object? innerException;

  final int? retryAfterSeconds;
}
