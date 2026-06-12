/// Emitted on `AudioVideoCallPlugin.incomingCalls` when a remote party
/// initiates a call to the local user.
class IncomingCallEvent {
  const IncomingCallEvent({
    required this.callId,
    required this.contactId,
    required this.isAudioOnly,
  });

  /// The MatrixRTC call session identifier.
  ///
  /// Pass this to `AudioVideoCallPlugin.acceptCall` or
  /// `AudioVideoCallPlugin.declineCall` to act on this specific call.
  final String callId;

  /// The app-level contact identity of the caller.
  final String contactId;

  /// Whether the incoming call was initiated as audio-only.
  final bool isAudioOnly;
}
