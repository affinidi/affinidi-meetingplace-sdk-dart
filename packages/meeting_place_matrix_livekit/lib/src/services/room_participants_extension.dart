import 'package:livekit_client/livekit_client.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart'
    show AudioVideoCallParticipant;

import 'participant_video_extension.dart';

/// Converts a LiveKit [Room] into the domain participant list.
extension RoomParticipantsExtension on Room {
  /// Maps all current participants — local and remote — to
  /// [AudioVideoCallParticipant] domain objects.
  ///
  /// [participantIdToDid] maps each expected participant identity (Matrix user
  /// id) to its permanent channel DID so the domain objects carry a stable DID
  /// rather than a transport identifier.
  List<AudioVideoCallParticipant> toParticipants(
    Map<String, String> participantIdToDid,
  ) {
    final self = localParticipant;
    final peers = remoteParticipants.values;

    return [
      if (self != null)
        AudioVideoCallParticipant(
          participantId: self.identity,
          did: participantIdToDid[self.identity],
          hasVideo: self.hasRenderableVideo,
          hasAudio: self.isMicrophoneEnabled(),
          isSpeaking: self.isSpeaking,
          isSelf: true,
        ),
      for (final p in peers)
        AudioVideoCallParticipant(
          participantId: p.identity,
          did: participantIdToDid[p.identity],
          hasVideo: p.hasRenderableVideo,
          hasAudio: p.isMicrophoneEnabled(),
          isSpeaking: p.isSpeaking,
        ),
    ];
  }
}
