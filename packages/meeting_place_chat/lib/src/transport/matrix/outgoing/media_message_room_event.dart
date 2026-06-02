import 'package:matrix/matrix.dart' show EventTypes;
import 'package:meeting_place_core/meeting_place_core.dart';

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

/// A [MatrixOutgoingMessage] for media (file/image/audio/video) messages.
///
/// Builds an `m.room.message` event following the Matrix Client-Server spec:
/// - Encrypted content: pass `encryptedFileJson` (the serialized `file` object
///   from the upload result containing the JWK, IV, and hashes).
/// - Unencrypted content: omit `encryptedFileJson`; `mxcUri` is placed in the
///   top-level `url` field.
///
/// `contentType` and `sizeBytes` are placed inside the `info` sub-object.
/// `filename` is included as a top-level field when provided.
/// `caption` overrides the `body` field; otherwise `filename` or msgtype is
/// used as a fallback.
class MediaMessageRoomEvent extends MatrixOutgoingMessage {
  MediaMessageRoomEvent({
    required super.senderDid,
    required String mxcUri,
    required String contentType,
    required int sizeBytes,
    String? filename,
    String? caption,
    Map<String, dynamic>? encryptedFileJson,
    super.notification,
  }) : super(
         type: EventTypes.Message,
         content: _buildContent(
           mxcUri: mxcUri,
           contentType: contentType,
           sizeBytes: sizeBytes,
           filename: filename,
           caption: caption,
           encryptedFileJson: encryptedFileJson,
         ),
       );

  static Map<String, dynamic> _buildContent({
    required String mxcUri,
    required String contentType,
    required int sizeBytes,
    String? filename,
    String? caption,
    Map<String, dynamic>? encryptedFileJson,
  }) {
    final msgtype = _msgtypeFromContentType(contentType);
    final body = caption ?? filename ?? msgtype;

    final info = <String, dynamic>{'mimetype': contentType, 'size': sizeBytes};

    final content = <String, dynamic>{
      'msgtype': msgtype,
      'body': body,
      'info': info,
    };

    if (filename != null) {
      content['filename'] = filename;
    }

    if (encryptedFileJson != null) {
      content['file'] = encryptedFileJson;
    } else {
      content['url'] = mxcUri;
    }

    return content;
  }

  static String _msgtypeFromContentType(String contentType) {
    if (contentType.startsWith('image/')) return MediaMsgType.image;
    if (contentType.startsWith('audio/')) return MediaMsgType.audio;
    if (contentType.startsWith('video/')) return MediaMsgType.video;
    return MediaMsgType.file;
  }
}
