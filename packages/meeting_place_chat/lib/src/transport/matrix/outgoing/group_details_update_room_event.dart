import 'package:meeting_place_core/meeting_place_core.dart';

import '../../didcomm/protocol/chat_group_details_update/chat_group_details_update.dart';
import '../matrix_chat_event_type.dart';

class GroupDetailsUpdateRoomEvent extends MatrixOutgoingMessage {
  factory GroupDetailsUpdateRoomEvent({
    required String senderDid,
    required Group group,
  }) {
    final update = ChatGroupDetailsUpdate.fromGroup(
      group,
      senderDid: senderDid,
    );
    return GroupDetailsUpdateRoomEvent._(
      senderDid: senderDid,
      content: update.body.toJson(),
    );
  }

  GroupDetailsUpdateRoomEvent._({
    required super.senderDid,
    required super.content,
  }) : super(type: MatrixChatEventType.groupDetailsUpdate);
}
