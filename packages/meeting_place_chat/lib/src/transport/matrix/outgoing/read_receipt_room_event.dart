import 'package:meeting_place_core/meeting_place_core.dart';

/// A [MatrixOutgoingMessage] that represents a native Matrix read receipt.
///
/// When sent via [MeetingPlaceCoreSDK.sendMessage], events of type `m.read`
/// are routed to `Room.setReadMarker` rather than `Room.sendEvent`, so no
/// custom timeline event is produced.
class ReadReceiptRoomEvent extends MatrixOutgoingMessage {
  ReadReceiptRoomEvent({required super.senderDid, required String eventId})
    : super(type: 'm.read', content: {'event_id': eventId});
}
