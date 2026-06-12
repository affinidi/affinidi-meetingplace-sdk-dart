import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_video_call_participant.freezed.dart';

/// Domain model for a single participant in a LiveKit call.
///
/// Wraps only the fields the UI cares about. The underlying
/// livekit_client Participant type stays inside LiveKitService.
@freezed
abstract class AudioVideoCallParticipant with _$AudioVideoCallParticipant {
  const factory AudioVideoCallParticipant({
    /// LiveKit participant identity string.
    required String identity,
    @Default(false) bool hasVideo,
    @Default(false) bool hasAudio,
    @Default(false) bool isSpeaking,
    @Default(false) bool isLocal,
  }) = _AudioVideoCallParticipant;
}
