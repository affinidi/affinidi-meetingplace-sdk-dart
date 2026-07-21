/// Identifies which phase of the call setup failed.
///
/// The presentation layer maps each value to a specific error message so the
/// UI shows a targeted message rather than a generic one.
enum AudioVideoCallErrorCode {
  /// No channel was found for the given contact DID.
  channelNotFound,

  /// The Matrix OpenID token or LiveKit JWT could not be obtained.
  tokenFetchFailed,

  /// The transport connection attempt failed.
  connectionFailed,

  /// The call-invite notification could not be delivered to the recipient.
  callInviteFailed,

  /// There was a network error
  networkError,

  /// An unclassified error occurred.
  unexpected,
}
