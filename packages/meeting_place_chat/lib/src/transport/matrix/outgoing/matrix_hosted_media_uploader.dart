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

  static final _dataUriPrefix = RegExp(r'^data:[^,]*;base64,');

  /// Prepares all [attachments] for sending. Returns only non-null results.
  Future<List<ChatAttachment>> prepareAll(
    List<ChatAttachment> attachments,
  ) async {
    final results = <ChatAttachment>[];
    for (final attachment in attachments) {
      final prepared = await prepare(attachment);
      if (prepared != null) results.add(prepared);
    }
    return results;
  }

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

    final rawBase64 = base64Content.replaceFirst(_dataUriPrefix, '');

    final uploaded = await _coreSDK.uploadMedia(
      base64Decode(const Base64Codec().normalize(rawBase64)),
      senderDid: _senderDid,
      contentType: attachment.mediaType ?? 'application/octet-stream',
      filename: attachment.filename,
    );

    final hosted = uploaded.toChatAttachment();
    return ChatAttachment(
      id: hosted.id,
      description: attachment.description ?? hosted.description,
      filename: hosted.filename ?? attachment.filename,
      mediaType: hosted.mediaType ?? attachment.mediaType,
      format: hosted.format,
      lastModifiedTime: attachment.lastModifiedTime ?? hosted.lastModifiedTime,
      data: hosted.data,
      byteCount: hosted.byteCount ?? attachment.byteCount,
    );
  }
}
