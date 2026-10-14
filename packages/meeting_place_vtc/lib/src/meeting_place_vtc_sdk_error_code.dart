/// Error codes raised by the Meeting Place VTC SDK.
enum MeetingPlaceVtcSDKErrorCode {
  /// A Trust Task document is missing a required field or has a wrong type.
  invalidDocument('vtc_invalid_document'),

  /// A document proof is missing, malformed, or its signature does not verify.
  invalidProof('vtc_invalid_proof');

  const MeetingPlaceVtcSDKErrorCode(this.value);

  /// Stable string form of the code, safe to log.
  final String value;
}
