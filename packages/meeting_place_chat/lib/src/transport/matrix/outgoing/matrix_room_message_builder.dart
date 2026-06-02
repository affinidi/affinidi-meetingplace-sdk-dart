import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../entity/chat_attachment.dart';
import '../matrix_media_attachment.dart';
import 'media_message_room_event.dart';
import 'text_message_room_event.dart';

/// Builds Matrix room messages from the chat-layer send inputs.
class MatrixRoomMessageBuilder {
  const MatrixRoomMessageBuilder();

  MatrixOutgoingMessage build({
    required String senderDid,
    required String text,
    required ChannelNotification notification,
    ChatAttachment? attachment,
  }) {
    if (attachment == null) {
      return TextMessageRoomEvent(
        senderDid: senderDid,
        text: text,
        notification: notification,
      );
    }

    final mxcUri = MatrixMediaAttachments.mediaUri(attachment);
    if (mxcUri != null) {
      return MediaMessageRoomEvent(
        senderDid: senderDid,
        mxcUri: mxcUri,
        contentType: attachment.mediaType ?? 'application/octet-stream',
        sizeBytes: attachment.byteCount ?? 0,
        filename: attachment.filename,
        caption: text.isNotEmpty ? text : null,
        encryptedFileInfo: MatrixMediaAttachments.encryptedFileInfo(attachment),
        notification: notification,
      );
    }

    return TextMessageRoomEvent(
      senderDid: senderDid,
      text: text,
      notification: notification,
    );
  }
}
