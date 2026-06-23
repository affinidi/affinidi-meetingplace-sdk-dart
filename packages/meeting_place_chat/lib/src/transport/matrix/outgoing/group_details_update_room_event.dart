import 'package:meeting_place_core/meeting_place_core.dart';

import '../../didcomm/protocol/chat_group_details_update/chat_group_details_update.dart';
import '../matrix_chat_event_type.dart';

class GroupDetailsUpdateRoomEvent extends MatrixOutgoingMessage {
  GroupDetailsUpdateRoomEvent({required super.senderDid, required Group group})
    : super(
        type: MatrixChatEventType.groupDetailsUpdate,
        content: ChatGroupDetailsUpdate.fromGroup(
          group,
          senderDid: senderDid,
        ).body.toJson(),
      );
}
