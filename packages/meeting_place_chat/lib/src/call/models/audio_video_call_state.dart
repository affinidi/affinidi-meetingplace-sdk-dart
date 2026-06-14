import './audio_video_call_error_code.dart';
import './audio_video_call_participant.dart';
import './audio_video_call_status.dart';

/// All state that an `AudioVideoCallSession` publishes for the presentation
/// layer to observe via `AudioVideoCallSession.state`.
///
/// UI-only fields (mic/camera toggle display state, permission errors) live in
/// the app-layer screen state, not here.
class AudioVideoCallState {
  const AudioVideoCallState({
    this.status = AudioVideoCallStatus.idle,
    this.participants = const [],
    this.errorCode,
  });

  final AudioVideoCallStatus status;
  final List<AudioVideoCallParticipant> participants;

  /// Non-null only when [status] is [AudioVideoCallStatus.error].
  final AudioVideoCallErrorCode? errorCode;

  /// The default initial state: idle, no participants, no error.
  static const initial = AudioVideoCallState();

  AudioVideoCallState copyWith({
    AudioVideoCallStatus? status,
    List<AudioVideoCallParticipant>? participants,
    AudioVideoCallErrorCode? errorCode,
    bool clearErrorCode = false,
  }) {
    return AudioVideoCallState(
      status: status ?? this.status,
      participants: participants ?? this.participants,
      errorCode: clearErrorCode ? null : (errorCode ?? this.errorCode),
    );
  }
}
