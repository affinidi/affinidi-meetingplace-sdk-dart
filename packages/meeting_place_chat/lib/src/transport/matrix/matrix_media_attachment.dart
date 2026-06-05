import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../entity/chat_attachment.dart';
import 'outgoing/media_message_room_event.dart';

/// Matrix-specific helpers for parsing and inspecting hosted-media attachments
/// carried inside Matrix room events.
///
/// All methods are static; this class exists purely to scope the helpers to
/// the Matrix transport layer.
class MatrixMediaAttachments {
  MatrixMediaAttachments._();

  static const Set<String> _mediaMsgTypes = {
    MediaMsgType.file,
    MediaMsgType.image,
    MediaMsgType.audio,
    MediaMsgType.video,
  };

  /// Extracts hosted-media attachments from Matrix `m.room.message` content.
  static List<ChatAttachment> extractFromContent(Map<String, dynamic> content) {
    final msgtype = _stringValue(content['msgtype']);
    if (msgtype == null || !_mediaMsgTypes.contains(msgtype)) {
      return const [];
    }

    final info = _mapValue(content['info']);
    final filename =
        _stringValue(content['filename']) ?? _stringValue(content['body']);
    final mimeType = _stringValue(info?['mimetype']);
    final sizeValue = info?['size'];
    final size = sizeValue is int ? sizeValue : null;

    final encryptedFile = _mapValue(content['file']);
    final mxcUrl =
        _stringValue(encryptedFile?[encryptedFileFieldUrl]) ??
        _stringValue(content['url']);
    if (mxcUrl == null) return const [];

    final mxcUri = Uri.tryParse(mxcUrl);
    if (mxcUri == null || mxcUri.scheme != matrixMxcScheme) return const [];

    String? encryptionJson;
    String? hash;
    if (encryptedFile != null) {
      encryptionJson = jsonEncode(encryptedFile);
      final hashes = _mapValue(encryptedFile[encryptedFileFieldHashes]);
      hash = _stringValue(hashes?[encryptedFileSha256Key]);
    }

    return [
      ChatAttachment(
        filename: filename,
        mediaType: mimeType,
        format: AttachmentFormat.hostedMedia.value,
        byteCount: size,
        data: ChatAttachmentData(
          links: [mxcUri],
          json: encryptionJson,
          hash: hash,
        ),
      ),
    ];
  }

  /// Extracts the user-visible caption from `m.room.message` content.
  ///
  /// For media messages (msgtype `m.image`/`m.audio`/`m.video`/`m.file`) the
  /// `body` field is a caption only when a separate `filename` field is
  /// present and differs from `body`; otherwise `body` carries the filename
  /// (or the msgtype as a last-resort placeholder per the Matrix spec) and is
  /// not user-visible text. Returns `null` for non-media messages so callers
  /// fall back to `body` for plain text messages.
  static String? extractCaption(Map<String, dynamic> content) {
    final msgtype = _stringValue(content['msgtype']);
    if (msgtype == null || !_mediaMsgTypes.contains(msgtype)) return null;

    final body = _stringValue(content['body']);
    final filename = _stringValue(content['filename']);
    if (filename == null) return '';
    if (body == null || body == filename) return '';
    return body;
  }

  /// Extracts the `mxc://` URI from a hosted-media chat attachment.
  static String? mediaUri(ChatAttachment attachment) {
    final links = attachment.data?.links;
    if (links == null || links.isEmpty) return null;

    final uri = links.first;
    return uri.scheme == matrixMxcScheme ? uri.toString() : null;
  }

  static String? _stringValue(Object? value) => value is String ? value : null;

  static Map<String, dynamic>? _mapValue(Object? value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }
}
