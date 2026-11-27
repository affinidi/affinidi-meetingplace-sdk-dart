/// @docImport '../entity/call_outcome_record.dart';
library;

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

  /// Timeline event written once by the first device to observe a call
  /// connect. Carries only `callId`; the homeserver's `originServerTs` on
  /// this event is the authoritative call start time, since no client clock
  /// in the payload can be trusted.
  static const String callStarted = 'mpx.call.started';

  /// Timeline event written when a participant leaves a call that carries the
  /// canonical [CallOutcomeRecord]. The homeserver's `originServerTs` on this
  /// event is the authoritative call end time; receivers reconcile the call
  /// chat item by `callId` and converge on the full call duration.
  static const String callOutcome = 'mpx.call.outcome';
}
