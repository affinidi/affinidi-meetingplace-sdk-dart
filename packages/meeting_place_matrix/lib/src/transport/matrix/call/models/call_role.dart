/// The local user's role in an audio/video call.
///
/// Resolved from the Matrix room's call membership at join time: the first
/// device to publish a call membership is the [caller]; a device that joins
/// while a membership already exists is the [recipient].
///
/// Consumers use this to attribute call-start side effects (e.g. emitting a
/// call chat item) to the caller only.
enum CallRole {
  /// This device started the call.
  caller,

  /// This device joined a call started by the other party.
  recipient,
}
