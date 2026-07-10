import 'audio_video_call_participant.dart';

/// The type of change that occurred in the participant list.
enum CallParticipantEventType {
  /// A peer participant joined the call.
  joined,

  /// A peer participant left the call.
  left,
}

/// A discrete event emitted when a peer participant joins or leaves the call.
///
/// Emitted by `AudioVideoCallSession.participantEvents`. Only covers peer
/// (non-self) participants — self-join is not emitted.
class CallParticipantEvent {
  const CallParticipantEvent({required this.type, required this.participant});

  final CallParticipantEventType type;
  final AudioVideoCallParticipant participant;
}
