// Internal helpers for decoding [ChatAttachment] inline base64 payloads into
// raw bytes. Used by both the matrix transport (to upload via the matrix SDK)
// and the DIDComm transport (to surface inline attachment bytes via
// `downloadMedia`).

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'chat_attachment.dart';

final _dataUriPrefix = RegExp(r'^data:[^,]*;base64,');

/// Decodes an inline `data:[mime];base64,...` URI or a bare base64 string
/// into raw bytes. Tolerant of unpadded input via [Base64Codec.normalize].
@internal
Uint8List decodeBase64Payload(String base64Payload) {
  final stripped = base64Payload.replaceFirst(_dataUriPrefix, '');
  return base64Decode(const Base64Codec().normalize(stripped));
}

/// Extracts and decodes the inline base64 payload from a [ChatAttachment].
/// Throws [StateError] if the attachment has no inline base64 data.
@internal
extension ChatAttachmentBytes on ChatAttachment {
  Uint8List decodeInlineBytes() {
    final payload = data?.base64;
    if (payload == null || payload.isEmpty) {
      throw StateError(
        'Attachment has no inline base64 payload; nothing to decode',
      );
    }
    return decodeBase64Payload(payload);
  }
}
