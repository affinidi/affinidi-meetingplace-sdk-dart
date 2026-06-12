/// Error codes used by `MeetingPlaceCredentialsSDKException`.
enum MeetingPlaceCredentialsSDKErrorCode {
  // vrc codes
  /// The received VC blob could not be parsed as a valid VRC.
  vrcInvalidCredential('credentials_vrc_invalid_credential'),
  vrcMissingCredentialSubject('credentials_vrc_missing_credential_subject'),
  sendVrcMissingChannel('credentials_send_vrc_missing_channel'),

  // rcard codes
  /// The R-Card VC is missing a `credentialSubject` entry.
  rCardMissingCredentialSubject('credentials_rcard_missing_credential_subject'),
  sendRCardMissingChannelDid('credentials_send_rcard_missing_channel_did'),

  // signing codes
  /// No assertion method key is available for signing a credential.
  signingKeyUnavailable('credentials_signing_key_unavailable'),

  // others
  /// A generic / unclassified error.
  generic('generic');

  const MeetingPlaceCredentialsSDKErrorCode(this.value);

  /// The string value used as the error code in exception messages.
  final String value;
}
