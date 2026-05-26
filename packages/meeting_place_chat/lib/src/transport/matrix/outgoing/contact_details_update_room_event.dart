import 'package:meeting_place_core/meeting_place_core.dart';

import '../chat_protocol.dart';

class ContactDetailsUpdateRoomEvent extends MatrixOutgoingMessage {
  ContactDetailsUpdateRoomEvent({
    required super.senderDid,
    required super.roomId,
    required Map<String, dynamic> profileDetails,
  }) : super(
         type: ChatProtocol.chatContactDetailsUpdate.value,
         content: {'profileDetails': profileDetails},
       );
}
