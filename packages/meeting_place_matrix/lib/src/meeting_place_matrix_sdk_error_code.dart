/// @docImport 'exception/matrix_sdk_exception.dart';
library;

/// Error codes carried by [MeetingPlaceMatrixSDKException], letting
/// consumers branch on the specific failure without parsing message text.
enum MeetingPlaceMatrixSDKErrorCode {
  /// Matrix login failed.
  matrixLoginFailed('matrix_login_failed'),

  /// An encrypted room operation was attempted before the Matrix client's
  /// encryption (vodozemac) finished initializing.
  matrixEncryptionNotEnabled('matrix_encryption_not_enabled'),

  /// An encrypted media attachment could not be decrypted because its
  /// megolm key is unavailable.
  matrixMediaDecryptionFailed('matrix_media_decryption_failed'),

  /// The Matrix client has no user ID after session establishment.
  matrixMissingUserId('matrix_missing_user_id'),

  /// A call operation was attempted before `initializeMatrixRTC()` was
  /// called.
  matrixVoipNotInitialized('matrix_voip_not_initialized'),

  /// VoIP was already initialized with a different Matrix client or WebRTC
  /// delegate.
  matrixVoipConflictForClient('matrix_voip_already_initialized'),

  /// The Matrix server denied this device permission to join a group call.
  matrixGroupCallPermissionDenied('matrix_group_call_permission_denied'),

  /// No Matrix room exists for the requested room ID.
  matrixRoomNotFound('matrix_room_not_found'),

  /// No incoming MatrixRTC call was found in the requested room.
  matrixIncomingCallNotFound('matrix_incoming_call_not_found'),

  /// A Matrix client operation failed due to an authentication error.
  matrixAuthError('matrix_auth_error'),

  /// Fallback code used when an unexpected error is wrapped into a
  /// [MeetingPlaceMatrixSDKException].
  generic('generic');

  const MeetingPlaceMatrixSDKErrorCode(this.value);

  /// The wire-stable string representation of this code.
  final String value;
}
