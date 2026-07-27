/// Matrix room event type constants for MPX call signalling.
///
/// The caller writes these events to the shared Matrix room so the recipient
/// can reconcile call state (e.g. cancellation, outcome) from the timeline.
abstract final class MpxCallEventType {
  /// Timeline event written by the caller when a pending call is cancelled
  /// before the recipient answers.
  static const String callCancel = 'mpx.call.cancel';

  /// Timeline event written after a call ends that carries call item metadata
  /// (e.g. duration, media type) for display in the chat history.
  static const String callItem = 'mpx.call.item';

  /// Timeline event written when a participant leaves a call that carries the
  /// canonical `CallOutcomeRecord`. The homeserver's `originServerTs` on this
  /// event is the authoritative call end time; receivers reconcile the call
  /// chat item by `callId` and converge on the full call duration.
  static const String callOutcome = 'mpx.call.outcome';
}
