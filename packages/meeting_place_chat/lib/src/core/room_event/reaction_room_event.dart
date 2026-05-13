import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

class ReactionRoomEvent extends MatrixRoomEvent {
  ReactionRoomEvent({
    required super.sender,
    required super.roomId,
    required String targetEventId,
    required String reaction,
  }) : super(
         id: const Uuid().v4(),
         type: 'm.reaction',
         content: {
           'm.relates_to': {
             'rel_type': 'm.annotation',
             'event_id': targetEventId,
             'key': reaction,
           },
         },
         timestamp: DateTime.now().toUtc(),
       );
}
