import 'dart:convert';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';

typedef MatrixTimelineEvent = matrix.Event;
typedef MatrixTimelineEventStream = Stream<MatrixTimelineEvent>;

class MatrixRoomMessageEvent {
  factory MatrixRoomMessageEvent.fromTimelineEvent(MatrixTimelineEvent event) {
    return MatrixRoomMessageEvent.fromParts(
      eventId: event.eventId,
      senderId: event.senderId,
      type: event.type,
      originServerTs: event.originServerTs,
      content: event.content,
    );
  }

  factory MatrixRoomMessageEvent.fromParts({
    required String eventId,
    required String senderId,
    required String type,
    required DateTime originServerTs,
    required Map<String, dynamic> content,
  }) {
    return MatrixRoomMessageEvent._(
      eventId: eventId,
      senderId: senderId,
      type: type,
      originServerTs: originServerTs,
      body: (content['body'] as String?) ?? '',
      mentionedUserIds: _mentionedUserIdsFromContent(content),
      attachment: _attachmentFromContent(content),
    );
  }

  const MatrixRoomMessageEvent._({
    required this.eventId,
    required this.senderId,
    required this.type,
    required this.originServerTs,
    required this.body,
    required this.mentionedUserIds,
    required this.attachment,
  });

  final String eventId;
  final String senderId;
  final String type;
  final DateTime originServerTs;
  final String body;
  final List<String> mentionedUserIds;
  final MatrixRoomMessageAttachment? attachment;

  bool get isRoomMessage => type == 'm.room.message';

  bool mentionsUser(String userId) => mentionedUserIds.contains(userId);

  static List<String> _mentionedUserIdsFromContent(
    Map<String, dynamic> content,
  ) {
    final mentions = content['m.mentions'];
    if (mentions is! Map) {
      return const <String>[];
    }

    return List<String>.from(
      (mentions['user_ids'] as List<dynamic>? ?? []).whereType<String>(),
    );
  }

  static MatrixRoomMessageAttachment? _attachmentFromContent(
    Map<String, dynamic> content,
  ) {
    final msgType = content['msgtype'] as String?;
    final uri = content['url'] as String?;
    final attachmentFormat = _attachmentFormatForMessageType(msgType);
    if (attachmentFormat == null || uri == null) {
      return null;
    }

    final filenameRaw = content['filename'] as String?;
    final bodyRaw = content['body'] as String?;
    final filename = (filenameRaw != null && filenameRaw.trim().isNotEmpty)
        ? filenameRaw.trim()
        : (bodyRaw != null && bodyRaw.trim().isNotEmpty)
        ? bodyRaw.trim()
        : _fallbackFilename(attachmentFormat);

    final info = content['info'];
    final infoMap = info is Map ? Map<String, dynamic>.from(info) : null;
    final infoMimeType = infoMap?['mimetype'] as String?;
    final infoFormat = infoMap?['format'] as String?;

    return MatrixRoomMessageAttachment(
      uri: uri,
      filename: filename,
      mediaType: (infoMimeType?.trim().isNotEmpty == true)
          ? infoMimeType!.trim()
          : AttachmentMediaType.applicationOctetStream.value,
      format: (infoFormat != null && infoFormat.trim().isNotEmpty)
          ? infoFormat.trim()
          : attachmentFormat.value,
      metadataJson: jsonEncode(<String, dynamic>{
        'msgtype': msgType,
        if (infoMap != null) ...infoMap,
      }),
    );
  }

  static AttachmentFormat? _attachmentFormatForMessageType(String? msgType) {
    switch (msgType) {
      case matrix.MessageTypes.Image:
        return AttachmentFormat.matrixImage;
      case matrix.MessageTypes.Audio:
        return AttachmentFormat.matrixAudio;
      default:
        return null;
    }
  }

  static String _fallbackFilename(AttachmentFormat attachmentFormat) {
    if (attachmentFormat == AttachmentFormat.matrixAudio) {
      return 'audio';
    }

    return 'image';
  }
}

class MatrixRoomMessageAttachment {
  const MatrixRoomMessageAttachment({
    required this.uri,
    required this.filename,
    required this.mediaType,
    required this.metadataJson,
    this.format,
  });

  final String uri;
  final String filename;
  final String mediaType;
  final String metadataJson;
  final String? format;
}
