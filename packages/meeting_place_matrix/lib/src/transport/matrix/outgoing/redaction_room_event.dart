import '../../../matrix_outgoing_message.dart';

class RedactionRoomEvent extends MatrixOutgoingMessage {
  RedactionRoomEvent({required super.senderDid, required String targetEventId})
    : super(type: 'm.room.redaction', content: {'redacts': targetEventId});
}
