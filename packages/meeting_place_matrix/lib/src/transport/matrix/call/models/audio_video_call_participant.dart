/// Domain model for a single participant in an audio/video call.
///
/// Wraps only the fields the presentation layer needs. Transport-specific
/// types (e.g. LiveKit `Participant`) stay inside the plugin implementation.
class AudioVideoCallParticipant {
  const AudioVideoCallParticipant({
    required this.participantId,
    this.did,
    this.hasVideo = false,
    this.hasAudio,
    this.isSpeaking = false,
    this.isSelf = false,
  });

  /// Stable identifier for the participant within the call session.
  ///
  /// Transport-agnostic: the plugin maps its transport-layer participant
  /// identifier onto this field so the presentation layer never depends on a
  /// specific transport (e.g. LiveKit) identity.
  final String participantId;

  /// Permanent channel DID of the participant, or `null` when it could not be
  /// resolved from [participantId].
  ///
  /// The presentation layer uses this to look up a display name (e.g. a group
  /// member's name) without needing to know how participants are identified at
  /// the transport layer.
  final String? did;

  /// Whether the participant's video track is currently active.
  final bool hasVideo;

  /// Whether the participant's audio track is currently active.
  final bool? hasAudio;

  /// Whether the participant is currently speaking.
  final bool isSpeaking;

  /// Whether this participant represents the self user.
  final bool isSelf;

  AudioVideoCallParticipant copyWith({
    String? participantId,
    String? did,
    bool? hasVideo,
    bool? hasAudio,
    bool? isSpeaking,
    bool? isSelf,
  }) {
    return AudioVideoCallParticipant(
      participantId: participantId ?? this.participantId,
      did: did ?? this.did,
      hasVideo: hasVideo ?? this.hasVideo,
      hasAudio: hasAudio ?? this.hasAudio,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isSelf: isSelf ?? this.isSelf,
    );
  }
}
