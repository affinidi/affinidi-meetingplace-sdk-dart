import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

class RedactionRoomEvent extends MatrixRoomEvent {
  RedactionRoomEvent({
    required super.sender,
    required super.roomId,
    required String targetEventId,
  }) : super(
         id: const Uuid().v4(),
         type: 'm.room.redaction',
         content: {'redacts': targetEventId},
         timestamp: DateTime.now().toUtc(),
       );
}
