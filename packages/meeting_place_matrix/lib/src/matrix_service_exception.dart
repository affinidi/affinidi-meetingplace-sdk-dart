import 'exception/matrix_sdk_exception.dart';
import 'meeting_place_matrix_sdk_error_code.dart';

class MatrixServiceException implements MatrixSDKException {
  factory MatrixServiceException.loginFailed({Object? innerException}) {
    return MatrixServiceException(
      message: 'Matrix login failed',
      code: MeetingPlaceMatrixSDKErrorCode.matrixLoginFailed,
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
      code: MeetingPlaceMatrixSDKErrorCode.matrixEncryptionNotEnabled,
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
      code: MeetingPlaceMatrixSDKErrorCode.matrixMediaDecryptionFailed,
      innerException: innerException,
    );
  }

  factory MatrixServiceException.missingUserId() {
    return MatrixServiceException(
      message:
          'Matrix client has no userID after session establishment; '
          'this should not happen.',
      code: MeetingPlaceMatrixSDKErrorCode.matrixMissingUserId,
    );
  }

  factory MatrixServiceException.voipNotInitialized() {
    return MatrixServiceException(
      message:
          'VoIP not initialized. '
          'Call initializeMatrixRTC() before starting a call.',
      code: MeetingPlaceMatrixSDKErrorCode.matrixVoipNotInitialized,
    );
  }

  factory MatrixServiceException.voipConflictForClient() {
    return MatrixServiceException(
      message:
          'VoIP already initialized with a different Matrix client or '
          'WebRTC delegate. Reuse the existing instance or dispose it '
          'before reinitializing.',
      code: MeetingPlaceMatrixSDKErrorCode.matrixVoipConflictForClient,
    );
  }

  factory MatrixServiceException.roomNotFound(String roomId) {
    return MatrixServiceException(
      message: 'Matrix room not found: $roomId',
      code: MeetingPlaceMatrixSDKErrorCode.matrixRoomNotFound,
    );
  }

  factory MatrixServiceException.groupCallPermissionDenied({
    required String roomId,
    required bool canJoinGroupCall,
    required bool groupCallsEnabledForEveryone,
  }) {
    return MatrixServiceException(
      message:
          'Matrix denied group call join for room $roomId '
          '(canJoinGroupCall=$canJoinGroupCall, '
          'groupCallsEnabledForEveryone=$groupCallsEnabledForEveryone).',
      code: MeetingPlaceMatrixSDKErrorCode.matrixGroupCallPermissionDenied,
    );
  }

  factory MatrixServiceException.incomingCallNotFound(String roomId) {
    return MatrixServiceException(
      message: 'No incoming MatrixRTC call found in room: $roomId',
      code: MeetingPlaceMatrixSDKErrorCode.matrixIncomingCallNotFound,
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
  final MeetingPlaceMatrixSDKErrorCode code;

  @override
  final Object? innerException;
}
