import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';

import '../entity/channel.dart';

class ControlPlaneStreamEvent {
  ControlPlaneStreamEvent({
    required this.channel,
    required this.type,
    this.activityType,
  });

  final Channel channel;
  final ControlPlaneEventType type;

  /// The `ChannelActivity.type` string (e.g. `'chat-activity'`).
  /// Non-null only when [type] is [ControlPlaneEventType.ChannelActivity].
  final String? activityType;

  bool matchesType(ControlPlaneEventType eventType) {
    return type == eventType;
  }
}
