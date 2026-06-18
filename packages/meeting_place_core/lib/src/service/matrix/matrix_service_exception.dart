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

  factory MatrixServiceException.mediaDecryptionFailed({
    required String roomId,
    required String eventId,
    Object? innerException,
  }) {
    return MatrixServiceException(
      message:
          'Matrix event $eventId in room $roomId could not be decrypted '
          '(megolm key unavailable); its attachment cannot be downloaded.',
      code: MeetingPlaceCoreSDKErrorCode.matrixMediaDecryptionFailed,
      innerException: innerException,
    );
  }

  factory MatrixServiceException.mediaNotCachedLocally({
    required String roomId,
    required String eventId,
    Object? innerException,
  }) {
    return MatrixServiceException(
      message:
          'Matrix event $eventId in room $roomId has no attachment in the '
          'local media cache; a local-only download cannot be served.',
      code: MeetingPlaceCoreSDKErrorCode.matrixMediaNotCachedLocally,
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
