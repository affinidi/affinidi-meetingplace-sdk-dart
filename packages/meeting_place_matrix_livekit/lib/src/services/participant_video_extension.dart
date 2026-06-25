import 'package:livekit_client/livekit_client.dart';

/// Video-readiness helpers on [Participant].
///
/// A track publication can exist and be unmuted before its track is subscribed
/// and decodable on this device. These helpers treat such a track as
/// non-renderable so the UI shows an avatar placeholder rather than a blank
/// frame.
extension ParticipantVideoExtension on Participant {
  /// Whether this participant has a subscribed, unmuted video track that can
  /// actually be rendered right now.
  bool get hasRenderableVideo => renderableVideoTrack != null;

  /// The first subscribed, unmuted video track, or `null` if none exists.
  VideoTrack? get renderableVideoTrack {
    final pub = videoTrackPublications
        .where((pub) => pub.track != null && !pub.muted)
        .firstOrNull;
    return pub?.track as VideoTrack?;
  }
}
