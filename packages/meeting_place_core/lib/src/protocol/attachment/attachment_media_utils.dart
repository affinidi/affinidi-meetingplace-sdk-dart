import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../service/matrix/media/encrypted_file_info.dart';
import '../../service/matrix/media/matrix_media_uri.dart';
import '../../service/matrix/media/media_service.dart';
import 'attachment_format.dart';

const _uuid = Uuid();

/// Creates a DIDComm [Attachment] from a media upload result.
///
/// The attachment uses [AttachmentData.links] for the mxc:// URI and
/// [AttachmentData.json] for the encryption metadata.
Attachment attachmentFromMediaUpload(
  MediaUploadOutput uploadOutput, {
  required String mediaType,
  String? filename,
  String? description,
}) {
  final encInfo = uploadOutput.encryptedFileInfo;
  final mxcUri = uploadOutput.result.contentUri;

  return Attachment(
    id: _uuid.v4(),
    description: description,
    filename: filename,
    mediaType: mediaType,
    format: AttachmentFormat.hostedMedia.value,
    byteCount: uploadOutput.result.sizeBytes,
    data: AttachmentData(
      links: [Uri.parse(mxcUri)],
      json: jsonEncode(encInfo.toJson()),
      hash: encInfo.hashes[encryptedFileSha256Key],
    ),
  );
}

/// Checks whether an [Attachment] is a hosted media reference.
bool isHostedMediaAttachment(Attachment attachment) {
  return attachment.format == AttachmentFormat.hostedMedia.value ||
      (attachment.data?.links?.isNotEmpty == true &&
          attachment.data!.links!.first.scheme == matrixMxcScheme);
}

/// Extracts the mxc:// URI from a hosted media attachment.
/// Returns null if the attachment is not a hosted media reference.
String? getMxcUri(Attachment attachment) {
  final links = attachment.data?.links;
  if (links == null || links.isEmpty) return null;
  final uri = links.first;
  return uri.scheme == matrixMxcScheme ? uri.toString() : null;
}

/// Extracts [EncryptedFileInfo] from a hosted media attachment.
/// Returns null if the attachment does not contain encryption metadata.
EncryptedFileInfo? getEncryptedFileInfo(Attachment attachment) {
  return tryParseEncryptedFileInfoJson(attachment.data?.json);
}

/// Parses hosted-media encryption metadata from a JSON payload.
///
/// Returns null when the payload is absent or does not look like a Matrix
/// encrypted file object.
EncryptedFileInfo? tryParseEncryptedFileInfoJson(String? jsonStr) {
  if (jsonStr == null || jsonStr.isEmpty) return null;

  try {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) return null;
    if (!decoded.containsKey(encryptedFileFieldVersion) ||
        !decoded.containsKey(encryptedFileFieldKey)) {
      return null;
    }
    return EncryptedFileInfo.fromJson(decoded);
  } on FormatException {
    return null;
  }
}
