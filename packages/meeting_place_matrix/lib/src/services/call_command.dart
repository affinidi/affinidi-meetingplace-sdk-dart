/// Sealed set of side-effect intents emitted by the call state reducer.
///
/// The service interprets these commands after applying the new state.
/// Keeping side effects out of the reducer makes each transition rule
/// independently testable.
sealed class CallCommand {}

/// Start the outgoing-ring no-answer timer.
class StartOutgoingTimeout extends CallCommand {}

/// Cancel the outgoing-ring no-answer timer.
class CancelOutgoingTimeout extends CallCommand {}

/// Start the E2EE key-ready fallback timer.
class StartE2eeTimeout extends CallCommand {}

/// Cancel the E2EE key-ready fallback timer.
class CancelE2eeTimeout extends CallCommand {}

/// Tell Matrix to signal that the call has ended and leave the room.
class LeaveMatrixCall extends CallCommand {}

/// Disconnect the LiveKit room.
class DisconnectRoom extends CallCommand {}

/// Send the call-cancel signal to the recipient.
class SendCallCancel extends CallCommand {}

/// Send the shared call outcome event.
class SendCallOutcome extends CallCommand {
  SendCallOutcome({required this.callId, required this.startedAt});

  final String callId;
  final DateTime startedAt;
}
