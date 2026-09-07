import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';

import '../entity/channel.dart';
import 'channel_activity_type.dart';

/// A control-plane event delivered for a specific [Channel].
class ControlPlaneStreamEvent {
  /// Creates a [ControlPlaneStreamEvent].
  ControlPlaneStreamEvent({
    required this.channel,
    required this.type,
    this.activityType,
  });

  /// The channel this event pertains to.
  final Channel channel;

  /// The kind of control-plane event.
  final ControlPlaneEventType type;

  /// The `ChannelActivity.type` string. See [ChannelActivityType] for the
  /// known values (e.g. [ChannelActivityType.chatActivity]).
  ///
  /// Kept as a plain string rather than an enum because the control-plane
  /// server treats this field as free-form and may introduce new values the
  /// SDK doesn't know about yet; see [ChannelActivityType]'s own doc.
  ///
  /// Non-null only when [type] is [ControlPlaneEventType.channelActivity].
  final String? activityType;

  /// Whether this event's [type] equals [eventType].
  bool matchesType(ControlPlaneEventType eventType) {
    return type == eventType;
  }
}
