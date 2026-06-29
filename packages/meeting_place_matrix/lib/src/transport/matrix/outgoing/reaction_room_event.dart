import '../../../matrix_outgoing_message.dart';

class ReactionRoomEvent extends MatrixOutgoingMessage {
  ReactionRoomEvent({
    required super.senderDid,
    required String targetEventId,
    required String reaction,
  }) : super(
         type: 'm.reaction',
         content: {
           'm.relates_to': {
             'rel_type': 'm.annotation',
             'event_id': targetEventId,
             'key': reaction,
           },
         },
       );
}
