import '../../../call/mpx_call_event_type.dart';
import '../../../matrix_outgoing_message.dart';
import '../matrix_media_attachment.dart';

/// A [MatrixOutgoingMessage] for call item metadata
/// (e.g. duration, media type).
///
/// Sends a `mpx.call.item` room event with the metadata embedded directly in
/// the event content under `mp_call_metadata`. No file bytes are uploaded.
/// The receiver reconstructs the attachment from the embedded metadata.
class CallItemRoomEvent extends MatrixOutgoingMessage {
  CallItemRoomEvent({
    required super.senderDid,
    required Map<String, dynamic> metadata,
    super.notification,
  }) : super(
         type: MpxCallEventType.callItem,
         content: {MatrixEventField.callMetadata: metadata},
       );
}
