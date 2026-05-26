import 'package:meeting_place_core/meeting_place_core.dart';

class ReactionRoomEvent extends MatrixOutgoingMessage {
  ReactionRoomEvent({
    required super.senderDid,
    required super.roomId,
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
