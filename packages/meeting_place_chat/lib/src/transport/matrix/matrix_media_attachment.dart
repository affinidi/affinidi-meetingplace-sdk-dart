import 'package:meeting_place_core/meeting_place_core.dart';

import '../../entity/chat_attachment.dart';

/// Matrix `msgtype` values used for media content.
///
/// These match the Matrix Client-Server specification for
/// `m.room.message` events carrying binary attachments.
class MediaMsgType {
  MediaMsgType._();

  static const file = 'm.file';
  static const image = 'm.image';
  static const audio = 'm.audio';
  static const video = 'm.video';
}

/// Custom field keys the SDK adds to matrix event `content`.
class MatrixEventField {
  MatrixEventField._();

  /// Correlates several matrix file events emitted by a single
  /// `sendTextMessage` call so the receiver can coalesce them back into one
  /// logical `Message` carrying multiple attachments.
  static const correlationId = 'mp_correlation_id';
}

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

  /// Extracts display-only attachment metadata from Matrix `m.room.message`
  /// content. The matrix event id (held by the parent `Message.transportId`)
  /// is the only reference needed to fetch the bytes via
  /// `MeetingPlaceChatSDK.downloadMedia(Message)` — the mxc URI and
  /// encrypted-file metadata are intentionally not surfaced to SDK consumers.
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

    return [
      ChatAttachment(
        filename: filename,
        mediaType: mimeType,
        format: AttachmentFormat.hostedMedia.value,
        byteCount: size,
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

  static String? _stringValue(Object? value) => value is String ? value : null;

  static Map<String, dynamic>? _mapValue(Object? value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }
}
