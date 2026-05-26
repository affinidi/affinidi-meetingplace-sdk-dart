import 'package:meeting_place_core/meeting_place_core.dart';

class RedactionRoomEvent extends MatrixOutgoingMessage {
  RedactionRoomEvent({
    required super.senderDid,
    required super.roomId,
    required String targetEventId,
  }) : super(
         type: 'm.room.redaction',
         content: {'redacts': targetEventId},
       );
}
