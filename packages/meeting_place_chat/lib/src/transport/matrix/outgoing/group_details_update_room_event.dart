import 'package:meeting_place_core/meeting_place_core.dart';

import '../../didcomm/protocol/chat_group_details_update/chat_group_details_update.dart';

class GroupDetailsUpdateRoomEvent extends MatrixOutgoingMessage {
  GroupDetailsUpdateRoomEvent({required super.senderDid, required Group group})
    : super(
        type: 'com.affinidi.chat.group-details-update',
        content: ChatGroupDetailsUpdate.fromGroup(
          group,
          senderDid: senderDid,
        ).body.toJson(),
      );
}
