import 'package:meeting_place_core/meeting_place_core.dart';

/// A [MatrixRoomEvent] that represents a native Matrix read receipt.
///
/// When sent via [sendMatrixRoomEvent], the underlying [MatrixService] routes
/// events of type `m.read` to [Room.setReadMarker] rather than
/// [Room.sendEvent], so no custom timeline event is produced.
class ReadReceiptRoomEvent extends MatrixRoomEvent {
  ReadReceiptRoomEvent({
    required super.senderDid,
    required super.roomId,
    required String eventId,
  }) : super(
         id: eventId,
         type: 'm.read',
         content: {'event_id': eventId},
         timestamp: DateTime.now().toUtc(),
       );
}
