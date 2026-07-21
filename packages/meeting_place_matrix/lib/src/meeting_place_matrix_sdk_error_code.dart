enum MeetingPlaceMatrixSDKErrorCode {
  matrixLoginFailed('matrix_login_failed'),
  matrixEncryptionNotEnabled('matrix_encryption_not_enabled'),
  matrixMediaDecryptionFailed('matrix_media_decryption_failed'),
  matrixMissingUserId('matrix_missing_user_id'),
  matrixVoipNotInitialized('matrix_voip_not_initialized'),
  matrixVoipConflictForClient('matrix_voip_already_initialized'),
  matrixGroupCallPermissionDenied('matrix_group_call_permission_denied'),
  matrixRoomNotFound('matrix_room_not_found'),
  matrixIncomingCallNotFound('matrix_incoming_call_not_found');

  const MeetingPlaceMatrixSDKErrorCode(this.value);
  final String value;
}
