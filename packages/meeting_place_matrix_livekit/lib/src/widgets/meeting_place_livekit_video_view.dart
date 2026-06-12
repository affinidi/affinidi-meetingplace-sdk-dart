import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    required this.identity,
    this.mirror = false,
  });

  final String otherPartyChannelDid;
  final String identity;
  final bool mirror;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      audioVideoCallServiceProvider(otherPartyChannelDid).select(
        (s) => s.participants
            .where((p) => p.identity == identity)
            .firstOrNull
            ?.hasVideo,
      ),
    );
    return ref
            .read(livekitServiceProvider(otherPartyChannelDid))
            .buildVideoView(identity, mirror: mirror) ??
        const SizedBox.shrink();
  }
}
