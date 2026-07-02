import 'package:meeting_place_core/meeting_place_core.dart'
    show MeetingPlaceCoreSDKErrorCode;

import 'exception/matrix_sdk_exception.dart';

class MatrixServiceException implements MatrixSDKException {
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
