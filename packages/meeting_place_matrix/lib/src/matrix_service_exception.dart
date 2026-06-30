import 'package:meeting_place_core/meeting_place_core.dart'
    show MeetingPlaceCoreSDKErrorCode;

import 'exception/matrix_sdk_exception.dart';

// TODO(SR): Use matrix SDK specific error codes
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

  factory MatrixServiceException.missingUserId() {
    return MatrixServiceException(
      message:
          'Matrix client has no userID after session establishment; '
          'this should not happen.',
      // code: MeetingPlaceCoreSDKErrorCode.matrixMissingUserId,
      code: MeetingPlaceCoreSDKErrorCode.generic,
    );
  }

  factory MatrixServiceException.voipNotInitialized() {
    return MatrixServiceException(
      message:
          'VoIP not initialized. '
          'Call initializeMatrixRTC() before starting a call.',
      // code: MeetingPlaceCoreSDKErrorCode.matrixVoipNotInitialized,
      code: MeetingPlaceCoreSDKErrorCode.generic,
    );
  }

  factory MatrixServiceException.roomNotFound(String roomId) {
    return MatrixServiceException(
      message: 'Matrix room not found: $roomId',
      // code: MeetingPlaceCoreSDKErrorCode.matrixRoomNotFound,
      code: MeetingPlaceCoreSDKErrorCode.generic,
    );
  }

  factory MatrixServiceException.incomingCallNotFound(String roomId) {
    return MatrixServiceException(
      message: 'No incoming MatrixRTC call found in room: $roomId',
      // code: MeetingPlaceCoreSDKErrorCode.matrixIncomingCallNotFound,
      code: MeetingPlaceCoreSDKErrorCode.generic,
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
