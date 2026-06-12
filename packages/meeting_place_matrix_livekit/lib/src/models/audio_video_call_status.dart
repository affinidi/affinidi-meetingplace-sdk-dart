enum AudioVideoCallStatus {
  /// No active call.
  idle,

  /// Caller side: waiting for the remote party to answer.
  outgoingRinging,

  /// Callee side: incoming call awaiting accept or decline.
  incoming,

  /// Connecting to the LiveKit room (transport layer).
  connecting,

  /// Connected to the room and media is flowing (transport layer).
  connected,

  /// Waiting for E2EE keys from remote participants.
  waitingForKeys,

  /// Call is live and media is flowing (UX layer).
  active,

  /// Leaving the call gracefully (transport layer).
  disconnecting,

  /// Call transport disconnected (transport layer).
  disconnected,

  /// Remote party declined the call.
  declined,

  /// No answer within the timeout window.
  missed,

  /// Call ended normally (UX layer).
  ended,

  /// An unrecoverable error occurred.
  error,
}
