import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../protocol/chat_protocol.dart';
import '../../../protocol/message/chat_group_details_update/chat_group_details_update.dart';

class GroupDetailsUpdateRoomEvent extends MatrixOutgoingMessage {
  GroupDetailsUpdateRoomEvent({
    required super.senderDid,
    required super.roomId,
    required Group group,
  }) : super(
         type: ChatProtocol.chatGroupDetailsUpdate.value,
         content: ChatGroupDetailsUpdate.fromGroup(
           group,
           senderDid: senderDid,
         ).body.toJson(),
       );
}
