import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart'
    show AudioVideoCallParticipant, AudioVideoCallState;

import '../providers/livekit_service_provider.dart';
import '../services/audio_video_call_service.dart';

/// Renders the video track for a participant in an active call.
///
/// Rebuilds only when the participant's `hasVideo` flag changes — not on
/// every call state update. Returns [SizedBox.shrink] when the room is
/// not connected, the participant is not found, or there is no active track.
class MeetingPlaceLiveKitVideoView extends ConsumerWidget {
  const MeetingPlaceLiveKitVideoView({
    super.key,
    required this.otherPartyChannelDid,
    required this.participantId,
    this.mirror = false,
  });

  final String otherPartyChannelDid;
  final String participantId;
  final bool mirror;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      audioVideoCallServiceProvider(otherPartyChannelDid).select<bool>((
        AudioVideoCallState? s,
      ) {
        if (s == null) return false;
        return s.participants
                .where(
                  (AudioVideoCallParticipant p) =>
                      p.participantId == participantId,
                )
                .firstOrNull
                ?.hasVideo ??
            false;
      }),
    );
    return ref
            .read(livekitServiceProvider(otherPartyChannelDid))
            .buildVideoView(participantId, mirror: mirror) ??
        const SizedBox.shrink();
  }
}
