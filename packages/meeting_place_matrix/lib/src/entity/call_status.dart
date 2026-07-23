/// The lifecycle state of a call chat item, as rendered to the local party.
///
/// The same call produces one chat item per side. The status is updated in
/// place via a message edit as the call progresses, so a single item moves
/// through these states rather than emitting a new item per transition.
enum CallStatus {
  /// Outgoing call, waiting for the peer to answer on the caller side.
  calling,

  /// Caller side: the remote device is ringing.
  ringing,

  /// A participant has joined; the call is active.
  inProgress,

  /// The local party left the call; shows the local participation duration.
  ended,

  /// The peer started and ended the call before it was answered.
  missed,

  /// Caller side: call ended without answer.
  declined,
}
