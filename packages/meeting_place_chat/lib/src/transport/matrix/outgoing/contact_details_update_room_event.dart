import 'package:meeting_place_core/meeting_place_core.dart';

class ContactDetailsUpdateRoomEvent extends MatrixOutgoingMessage {
  ContactDetailsUpdateRoomEvent({
    required super.senderDid,
    required super.roomId,
    required Map<String, dynamic> profileDetails,
  }) : super(
         type: 'com.affinidi.chat.contact-details-update',
         content: {'profileDetails': profileDetails},
       );
}
