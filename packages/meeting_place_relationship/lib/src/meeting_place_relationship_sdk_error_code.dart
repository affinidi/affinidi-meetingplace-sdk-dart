enum MeetingPlaceRelationshipSDKErrorCode {
  // vrc codes
  vrcInvalidCredential('relationship_vrc_invalid_credential'),

  // rcard codes
  rCardMissingCredentialSubject(
    'relationship_rcard_missing_credential_subject',
  ),

  // signing codes
  signingKeyUnavailable('relationship_signing_key_unavailable'),

  // others
  generic('generic');

  const MeetingPlaceRelationshipSDKErrorCode(this.value);
  final String value;
}
