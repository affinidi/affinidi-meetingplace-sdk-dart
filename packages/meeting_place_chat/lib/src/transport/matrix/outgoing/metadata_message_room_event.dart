import 'package:matrix/matrix.dart' show EventTypes;
import 'package:meeting_place_core/meeting_place_core.dart';

import '../matrix_media_attachment.dart';

/// A [MatrixOutgoingMessage] for metadata-only attachments (e.g. call items).
///
/// Sends a single `m.room.message` event with a custom msgtype
/// (`mpx.call.item`) and the attachment metadata embedded in the event
/// content under `mp_call_metadata`. No file bytes are uploaded.
/// The receiver reconstructs the attachment from the embedded metadata.
class MetadataMessageRoomEvent extends MatrixOutgoingMessage {
  MetadataMessageRoomEvent({
    required super.senderDid,
    required Map<String, dynamic> metadata,
    super.notification,
  }) : super(
         type: EventTypes.Message,
         content: {
           'body': '',
           'msgtype': MediaMsgType.callItem,
           MatrixEventField.callMetadata: metadata,
         },
       );
}
