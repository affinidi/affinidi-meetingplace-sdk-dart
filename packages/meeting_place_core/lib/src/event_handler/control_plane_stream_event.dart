import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';

import '../entity/channel.dart';

class ControlPlaneStreamEvent {
  ControlPlaneStreamEvent({required this.channel, required this.type});

  final Channel channel;
  final ControlPlaneEventType type;

  bool matchesType(ControlPlaneEventType eventType) {
    return type == eventType;
  }
}
