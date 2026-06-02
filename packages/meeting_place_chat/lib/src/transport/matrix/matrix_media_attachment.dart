import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../entity/chat_attachment.dart';
import 'outgoing/media_message_room_event.dart';

const _matrixMediaMsgTypes = {
  MediaMsgType.file,
  MediaMsgType.image,
  MediaMsgType.audio,
  MediaMsgType.video,
};

/// Extracts hosted-media attachments from Matrix `m.room.message` content.
List<ChatAttachment> extractMatrixMediaAttachments(
  Map<String, dynamic> content,
) {
  final msgtype = _stringValue(content['msgtype']);
  if (msgtype == null || !_matrixMediaMsgTypes.contains(msgtype)) {
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
      _stringValue(encryptedFile?['url']) ?? _stringValue(content['url']);
  if (mxcUrl == null) return const [];

  final mxcUri = Uri.tryParse(mxcUrl);
  if (mxcUri == null || mxcUri.scheme != 'mxc') return const [];

  String? encryptionJson;
  String? hash;
  if (encryptedFile != null) {
    encryptionJson = jsonEncode(encryptedFile);
    final hashes = _mapValue(encryptedFile['hashes']);
    hash = _stringValue(hashes?['sha256']);
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

/// Extracts the `mxc://` URI from a hosted-media chat attachment.
String? getMatrixMediaUri(ChatAttachment attachment) {
  final links = attachment.data?.links;
  if (links == null || links.isEmpty) return null;

  final uri = links.first;
  return uri.scheme == 'mxc' ? uri.toString() : null;
}

/// Extracts Matrix encrypted-file metadata from a hosted-media chat
/// attachment.
EncryptedFileInfo? getMatrixEncryptedFileInfo(ChatAttachment attachment) {
  return tryParseEncryptedFileInfoJson(attachment.data?.json);
}

String? _stringValue(Object? value) => value is String ? value : null;

Map<String, dynamic>? _mapValue(Object? value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}
