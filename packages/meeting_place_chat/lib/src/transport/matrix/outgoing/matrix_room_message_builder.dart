import 'package:meeting_place_core/meeting_place_core.dart';

import 'text_message_room_event.dart';

/// Builds Matrix room messages from the chat-layer text-send inputs.
///
/// Media-bearing events (`m.image`/`m.audio`/`m.video`/`m.file`) are produced
/// by `MeetingPlaceCoreSDK.sendMediaMessage`, which owns encryption and upload
/// atomically; this builder only handles the text path.
class MatrixRoomMessageBuilder {
  const MatrixRoomMessageBuilder();

  MatrixOutgoingMessage build({
    required String senderDid,
    required String text,
    required ChannelNotification notification,
  }) {
    return TextMessageRoomEvent(
      senderDid: senderDid,
      text: text,
      notification: notification,
    );
  }
}
