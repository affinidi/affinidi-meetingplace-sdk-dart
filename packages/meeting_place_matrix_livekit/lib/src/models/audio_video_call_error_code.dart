/// Identifies the phase of the call setup that failed.
///
/// The controller maps each value to a specific l10n string so the UI shows
/// a targeted error message rather than a generic one.
enum AudioVideoCallErrorCode {
  /// No channel was found for the given contact DID.
  channelNotFound,

  /// The Matrix OpenID token or LiveKit JWT could not be obtained.
  tokenFetchFailed,

  /// The LiveKit SFU connection attempt failed.
  connectionFailed,

  /// The call-invite notification could not be delivered to the callee.
  callInviteFailed,

  /// An unclassified error occurred.
  unexpected,
}
