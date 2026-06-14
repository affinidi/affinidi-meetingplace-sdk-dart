import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart'
    show AudioVideoCallParticipant, AudioVideoCallSession, AudioVideoCallState;

import '../providers/livekit_service_provider.dart';
import '../services/audio_video_call_service.dart';
import '../sessions/livekit_call_session.dart';
import 'plugin_scope.dart';

/// Renders the video track for a call participant.
///
/// Must be a descendant of the scope returned by
/// `MeetingPlaceLiveKitCallPlugin.scope`, or wrapped in one via `withScope`.
///
/// Returns [SizedBox.shrink] when the participant has no active video track.
/// Pass [mirror] = true for the local camera preview.
class AudioVideoCallView extends StatelessWidget {
  const AudioVideoCallView({
    super.key,
    required this.session,
    required this.participantIdentity,
    this.mirror = false,
  });

  final AudioVideoCallSession session;
  final String participantIdentity;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    if (session is! LiveKitCallSession) return const SizedBox.shrink();
    final lkSession = session as LiveKitCallSession;
    return PluginScope(
      container: lkSession.container,
      child: _VideoViewInScope(
        otherPartyChannelDid: lkSession.otherPartyChannelDid,
        identity: participantIdentity,
        mirror: mirror,
      ),
    );
  }
}

class _VideoViewInScope extends ConsumerWidget {
  const _VideoViewInScope({
    required this.otherPartyChannelDid,
    required this.identity,
    required this.mirror,
  });

  final String otherPartyChannelDid;
  final String identity;
  final bool mirror;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      audioVideoCallServiceProvider(otherPartyChannelDid).select<bool>(
        (AudioVideoCallState? s) {
          if (s == null) return false;
          return s.participants
              .where((AudioVideoCallParticipant p) => p.identity == identity)
              .firstOrNull
              ?.hasVideo ??
              false;
        },
      ),
    );
    return ref
            .read(livekitServiceProvider(otherPartyChannelDid))
            .buildVideoView(identity, mirror: mirror) ??
        const SizedBox.shrink();
  }
}
