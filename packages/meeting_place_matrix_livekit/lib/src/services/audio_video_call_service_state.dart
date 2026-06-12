import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/audio_video_call_error_code.dart';
import '../models/audio_video_call_participant.dart';
import '../models/audio_video_call_status.dart';

part 'audio_video_call_service_state.freezed.dart';

/// All state that AudioVideoCallService publishes for the presentation layer
/// to observe.
///
/// UI-only fields (mic/camera toggle display state) live in
/// `AudioVideoCallScreenState` in the reference app.
@Freezed(fromJson: false, toJson: false)
abstract class AudioVideoCallServiceState with _$AudioVideoCallServiceState {
  AudioVideoCallServiceState._();

  factory AudioVideoCallServiceState({
    @Default(AudioVideoCallStatus.idle) AudioVideoCallStatus status,
    @Default([]) List<AudioVideoCallParticipant> participants,

    /// Non-null only when [status] is [AudioVideoCallStatus.error].
    AudioVideoCallErrorCode? errorCode,
  }) = _AudioVideoCallServiceState;
}
