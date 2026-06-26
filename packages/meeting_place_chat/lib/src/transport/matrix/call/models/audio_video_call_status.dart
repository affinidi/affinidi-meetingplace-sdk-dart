/// The lifecycle phase of an audio/video call.
enum AudioVideoCallStatus {
  /// No active call.
  idle,

  /// Caller side: waiting for the remote party to answer.
  outgoingRinging,

  /// Callee side: incoming call awaiting accept or decline.
  incoming,

  /// Connecting to the call transport layer.
  connecting,

  /// Connected to the call transport (media may not be flowing yet).
  connected,

  /// Waiting for end-to-end encryption keys from remote participants.
  waitingForKeys,

  /// Call is live and media is flowing.
  active,

  /// Leaving the call gracefully.
  disconnecting,

  /// Transport disconnected.
  disconnected,

  /// Remote party declined the call.
  declined,

  /// No answer within the timeout window.
  missed,

  /// Call ended normally.
  ended,

  /// An unrecoverable error occurred.
  error,
}
