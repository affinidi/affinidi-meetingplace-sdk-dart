import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../../protocol/chat_protocol.dart';

class ContactDetailsUpdateRoomEvent extends MatrixRoomEvent {
  ContactDetailsUpdateRoomEvent({
    required super.senderDid,
    required super.roomId,
    required Map<String, dynamic> profileDetails,
  }) : super(
         id: const Uuid().v4(),
         type: ChatProtocol.chatContactDetailsUpdate.value,
         content: {'profileDetails': profileDetails},
         timestamp: DateTime.now().toUtc(),
       );
}
