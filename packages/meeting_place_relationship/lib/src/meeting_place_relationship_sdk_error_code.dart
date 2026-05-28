/// Error codes used by `MeetingPlaceRelationshipSDKException`.
enum MeetingPlaceRelationshipSDKErrorCode {
  // vrc codes
  /// The received VC blob could not be parsed as a valid VRC.
  vrcInvalidCredential('relationship_vrc_invalid_credential'),
  vrcMissingCredentialSubject('relationship_vrc_missing_credential_subject'),
  sendVrcMissingChannel('relationship_send_vrc_missing_channel'),

  // rcard codes
  /// The R-Card VC is missing a `credentialSubject` entry.
  rCardMissingCredentialSubject(
    'relationship_rcard_missing_credential_subject',
  ),
  sendRCardMissingChannelDid('relationship_send_rcard_missing_channel_did'),

  // signing codes
  /// No assertion method key is available for signing a credential.
  signingKeyUnavailable('relationship_signing_key_unavailable'),

  // others
  /// A generic / unclassified error.
  generic('generic');

  const MeetingPlaceRelationshipSDKErrorCode(this.value);

  /// The string value used as the error code in exception messages.
  final String value;
}
