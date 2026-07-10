import '../../../matrix_outgoing_message.dart';

import '../matrix_chat_event_type.dart';

class ContactDetailsUpdateRoomEvent extends MatrixOutgoingMessage {
  ContactDetailsUpdateRoomEvent({
    required super.senderDid,
    required Map<String, dynamic> profileDetails,
  }) : super(
         type: MatrixChatEventType.contactDetailsUpdate,
         content: {'profileDetails': profileDetails},
       );
}
