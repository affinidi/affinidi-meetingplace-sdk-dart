import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../entity/chat_attachment.dart';
import '../../../entity/chat_attachment_conversion.dart';
import '../matrix_media_attachment.dart';

/// Uploads chat attachments to the Matrix homeserver and returns the
/// hosted-media reference as a [ChatAttachment].
///
/// Hosted media flow:
/// - If the attachment already carries an `mxc://` URI, return it unchanged.
/// - Otherwise, decode `data.base64`, upload the bytes through the core SDK,
///   and produce a fresh hosted-media [ChatAttachment].
class MatrixHostedMediaUploader {
  MatrixHostedMediaUploader({
    required MeetingPlaceCoreSDK coreSDK,
    required String senderDid,
  }) : _coreSDK = coreSDK,
       _senderDid = senderDid;

  final MeetingPlaceCoreSDK _coreSDK;
  final String _senderDid;

  /// Prepares [attachment] for sending. Returns `null` when [attachment] is
  /// `null`. Throws [ArgumentError] if the attachment carries neither an
  /// `mxc://` URI nor base64 bytes.
  Future<ChatAttachment?> prepare(ChatAttachment? attachment) async {
    if (attachment == null) return null;

    if (MatrixMediaAttachments.mediaUri(attachment) != null) {
      return attachment;
    }

    final base64Content = attachment.data?.base64;
    if (base64Content == null || base64Content.isEmpty) {
      throw ArgumentError(
        'Attachment must contain either base64 data or an mxc:// URI',
      );
    }

    final uploadOutput = await _coreSDK.uploadMedia(
      base64Decode(const Base64Codec().normalize(base64Content)),
      senderDid: _senderDid,
      contentType: attachment.mediaType ?? 'application/octet-stream',
      filename: attachment.filename,
    );

    return attachmentFromMediaUpload(
      uploadOutput,
      mediaType: attachment.mediaType ?? 'application/octet-stream',
      filename: attachment.filename,
      description: attachment.description,
    ).toChatAttachment();
  }
}
