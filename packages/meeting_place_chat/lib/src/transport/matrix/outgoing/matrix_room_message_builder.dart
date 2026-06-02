import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../entity/chat_attachment.dart';
import '../matrix_media_attachment.dart';
import 'media_message_room_event.dart';
import 'text_message_room_event.dart';
import 'validated_encrypted_file.dart';

/// Builds Matrix room messages from the chat-layer send inputs.
///
/// Throws [ArgumentError] if a hosted-media attachment carries encryption
/// metadata that fails validation. Malformed encrypted metadata is never
/// silently downgraded into an unencrypted media event.
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
      final encryptionJson = attachment.data?.json;
      Map<String, dynamic>? encryptedFileMap;

      if (encryptionJson != null && encryptionJson.isNotEmpty) {
        final validated = ValidatedEncryptedFile.tryParse(
          encryptionJson,
          expectedMxcUri: mxcUri,
        );
        if (validated == null) {
          throw ArgumentError(
            'Attachment carries invalid encrypted-file metadata '
            '(expected valid Matrix encrypted file with matching mxc URI)',
          );
        }
        encryptedFileMap = validated.json;
      }

      return MediaMessageRoomEvent(
        senderDid: senderDid,
        mxcUri: mxcUri,
        contentType: attachment.mediaType ?? 'application/octet-stream',
        sizeBytes: attachment.byteCount ?? 0,
        filename: attachment.filename,
        caption: text.isNotEmpty ? text : null,
        encryptedFileJson: encryptedFileMap,
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
