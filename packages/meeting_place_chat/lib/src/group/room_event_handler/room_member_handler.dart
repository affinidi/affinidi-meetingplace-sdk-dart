import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../sdk/room_event_handler/room_event_handler.dart';
import 'member_deregistered_handler.dart';
import 'member_joined_handler.dart';

/// Dispatches `m.room.member` events to join/leave handlers based on the
/// `membership` field of the event content.
class RoomMemberHandler implements RoomEventHandler {
  RoomMemberHandler({
    required MemberJoinedHandler joinedHandler,
    required MemberDeregisteredHandler leftHandler,
  }) : _joinedHandler = joinedHandler,
       _leftHandler = leftHandler;

  final MemberJoinedHandler _joinedHandler;
  final MemberDeregisteredHandler _leftHandler;

  @override
  Future<void> handle(MatrixRoomEvent event) async {
    final membership = event.content['membership'] as String?;
    if (membership == matrix.Membership.join.name) {
      return _joinedHandler.handle(event);
    }
    if (membership == matrix.Membership.leave.name) {
      return _leftHandler.handle(event);
    }
  }
}
