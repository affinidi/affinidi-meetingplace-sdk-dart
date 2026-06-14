/// Domain model for a single participant in an audio/video call.
///
/// Wraps only the fields the presentation layer needs. Transport-specific
/// types (e.g. LiveKit `Participant`) stay inside the plugin implementation.
class AudioVideoCallParticipant {
  const AudioVideoCallParticipant({
    required this.identity,
    this.hasVideo = false,
    this.hasAudio = false,
    this.isSpeaking = false,
    this.isLocal = false,
  });

  /// Stable identifier for the participant within the call session.
  final String identity;

  /// Whether the participant's video track is currently active.
  final bool hasVideo;

  /// Whether the participant's audio track is currently active.
  final bool hasAudio;

  /// Whether the participant is currently speaking.
  final bool isSpeaking;

  /// Whether this participant represents the local user.
  final bool isLocal;

  AudioVideoCallParticipant copyWith({
    String? identity,
    bool? hasVideo,
    bool? hasAudio,
    bool? isSpeaking,
    bool? isLocal,
  }) {
    return AudioVideoCallParticipant(
      identity: identity ?? this.identity,
      hasVideo: hasVideo ?? this.hasVideo,
      hasAudio: hasAudio ?? this.hasAudio,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isLocal: isLocal ?? this.isLocal,
    );
  }
}
