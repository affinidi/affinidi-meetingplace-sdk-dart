import 'package:meeting_place_core/meeting_place_core.dart';

import 'call_channel_activity_type.dart';
import 'call_media_type.dart';
import 'call_signal.dart';

class CallSignalMapper {
  CallSignalMapper(Stream<ControlPlaneStreamEvent> controlPlaneEvents)
    : _events = controlPlaneEvents;

  final Stream<ControlPlaneStreamEvent> _events;

  Stream<CallSignal> get callSignals => _events.expand((e) {
    final did = e.channel.permanentChannelDid;
    if (did == null) return const <CallSignal>[];
    return switch (e.activityType) {
      CallChannelActivityType.callInviteVideo => [
        IncomingCallSignal(ownChannelDid: did, mediaType: CallMediaType.video),
      ],
      CallChannelActivityType.callInviteAudio => [
        IncomingCallSignal(ownChannelDid: did, mediaType: CallMediaType.audio),
      ],
      CallChannelActivityType.callDecline => [
        CallDeclineSignal(ownChannelDid: did),
      ],
      _ => const <CallSignal>[],
    };
  });
}
