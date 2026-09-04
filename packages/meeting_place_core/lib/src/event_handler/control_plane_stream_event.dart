import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';

import '../entity/channel.dart';
import 'channel_activity_type.dart';

class ControlPlaneStreamEvent {
  ControlPlaneStreamEvent({
    required this.channel,
    required this.type,
    this.activityType,
  });

  final Channel channel;
  final ControlPlaneEventType type;

  /// The `ChannelActivity.type` string. See [ChannelActivityType] for the
  /// known values (e.g. [ChannelActivityType.chatActivity]).
  ///
  /// Kept as a plain string rather than an enum because the control-plane
  /// server treats this field as free-form and may introduce new values the
  /// SDK doesn't know about yet; see [ChannelActivityType]'s own doc.
  ///
  /// Non-null only when [type] is [ControlPlaneEventType.ChannelActivity].
  final String? activityType;

  bool matchesType(ControlPlaneEventType eventType) {
    return type == eventType;
  }
}
