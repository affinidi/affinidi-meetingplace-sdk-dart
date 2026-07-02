/// Matrix room event type constants for MPX call signalling.
///
/// The caller writes these events to the shared Matrix room so the recipient
/// can read the call parameters (e.g. media type) when processing a
/// control-plane `call-invite` nudge.
abstract final class MpxCallEventType {
  /// Timeline event written by the caller that carries the call invite
  /// parameters, including the call's media type.
  static const String callInvite = 'mpx.call.invite';

  /// Timeline event written after a call ends that carries call item metadata
  /// (e.g. duration, media type) for display in the chat history.
  static const String callItem = 'mpx.call.item';
}
