enum MeetingPlaceRelationshipSDKErrorCode {
  // vrc codes
  vrcInvalidCredential('relationship_vrc_invalid_credential'),
  vrcMissingCredentialSubject('relationship_vrc_missing_credential_subject'),
  sendVrcMissingChannel('relationship_send_vrc_missing_channel'),

  // rcard codes
  rCardMissingCredentialSubject(
    'relationship_rcard_missing_credential_subject',
  ),
  sendRCardMissingChannelDid('relationship_send_rcard_missing_channel_did'),

  // signing codes
  signingKeyUnavailable('relationship_signing_key_unavailable'),

  // others
  generic('generic');

  const MeetingPlaceRelationshipSDKErrorCode(this.value);
  final String value;
}
