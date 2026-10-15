/// Error codes raised by the Meeting Place VTC SDK.
enum MeetingPlaceVtcSDKErrorCode {
  /// A Trust Task document is missing a required field or has a wrong type.
  invalidDocument('vtc_invalid_document'),

  /// A document proof is missing, malformed, or its signature does not verify.
  invalidProof('vtc_invalid_proof'),

  /// The community's DID could not be resolved or verified.
  didResolutionFailed('vtc_did_resolution_failed'),

  /// The community's DID document does not publish wallet sign-in.
  signInNotOffered('vtc_sign_in_not_offered'),

  /// The member's VTA has no DID hosting server to publish a persona on.
  didHostingMissing('vtc_did_hosting_missing'),

  /// The service could not be reached or answered with something that is not
  /// a Trust Task document.
  transportFailed('vtc_transport_failed'),

  /// The service answered with a Trust Task error; see the refusal code.
  refused('vtc_refused');

  const MeetingPlaceVtcSDKErrorCode(this.value);

  /// Stable string form of the code, safe to log.
  final String value;
}
