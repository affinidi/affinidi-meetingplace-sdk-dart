import 'package:meeting_place_core/meeting_place_core.dart';

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
