// Internal conversion helpers between [ChatAttachment]/[ChatAttachmentData]
// and DIDComm's [Attachment]/[AttachmentData].
//
// This file is intentionally NOT re-exported from meeting_place_chat.dart.
// Only SDK-internal code should import it.

import 'package:didcomm/didcomm.dart' show Attachment, AttachmentData;
import 'package:meta/meta.dart';

import 'chat_attachment.dart';

/// Converts DIDComm [AttachmentData] ↔ [ChatAttachmentData].
@internal
extension ChatAttachmentDataConversion on ChatAttachmentData {
  AttachmentData toDIDComm() => AttachmentData(
    jws: jws,
    hash: hash,
    links: links,
    base64: base64,
    json: json,
  );
}

/// Converts [ChatAttachment] → DIDComm [Attachment].
@internal
extension ChatAttachmentToDIDComm on ChatAttachment {
  Attachment toDIDComm() => Attachment(
    id: id,
    description: description,
    filename: filename,
    mediaType: mediaType,
    format: format,
    lastModifiedTime: lastModifiedTime,
    data: data?.toDIDComm(),
    byteCount: byteCount,
  );
}

/// Converts DIDComm [Attachment] → [ChatAttachment].
@internal
extension AttachmentToChatAttachment on Attachment {
  ChatAttachment toChatAttachment() => ChatAttachment(
    id: id,
    description: description,
    filename: filename,
    mediaType: mediaType,
    format: format,
    lastModifiedTime: lastModifiedTime,
    data: data == null
        ? null
        : ChatAttachmentData(
            jws: data!.jws,
            hash: data!.hash,
            links: data!.links,
            base64: data!.base64,
            json: data!.json,
          ),
    byteCount: byteCount,
  );
}
