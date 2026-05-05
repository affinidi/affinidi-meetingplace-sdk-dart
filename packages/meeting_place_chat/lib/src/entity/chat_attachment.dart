import 'chat_attachment_data.dart';

export 'chat_attachment_data.dart';

/// A transport-agnostic attachment for chat messages.
///
/// [ChatAttachment] replaces the DIDComm-specific `Attachment` type on the
/// public SDK boundary. The SDK converts to and from the wire format
/// internally. The JSON serialization is wire-compatible with DIDComm so that
/// persisted messages remain readable.
class ChatAttachment {
  ChatAttachment({
    this.id,
    this.description,
    this.filename,
    this.mediaType,
    this.format,
    this.lastModifiedTime,
    this.data,
    this.byteCount,
  });

  /// Deserialises a [ChatAttachment] from a JSON map.
  ///
  /// The key names match the DIDComm wire format so that persisted
  /// messages remain fully round-trippable.
  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      id: json['id'] as String?,
      description: json['description'] as String?,
      filename: json['filename'] as String?,
      mediaType: json['media_type'] as String?,
      format: json['format'] as String?,
      lastModifiedTime: json['lastmod_time'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (json['lastmod_time'] as int) * 1000,
              isUtc: true,
            ),
      data: json['data'] == null
          ? null
          : ChatAttachmentData.fromJson(json['data'] as Map<String, dynamic>),
      byteCount: json['byte_count'] as int?,
    );
  }

  /// Unique identifier for the attachment.
  final String? id;

  /// Human-readable description of the attachment content.
  final String? description;

  /// Hint for the file name if persisted.
  final String? filename;

  /// MIME type of the attached content (JSON key: `media_type`).
  final String? mediaType;

  /// Further format description beyond [mediaType].
  final String? format;

  /// Last modified timestamp (JSON key: `lastmod_time`, epoch seconds).
  final DateTime? lastModifiedTime;

  /// The attachment data payload.
  final ChatAttachmentData? data;

  /// Size in bytes (JSON key: `byte_count`).
  final int? byteCount;

  /// Serialises this [ChatAttachment] to a JSON map.
  ///
  /// The key names match the DIDComm wire format so that persisted
  /// messages remain fully round-trippable.
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    if (id != null) result['id'] = id;
    if (description != null) result['description'] = description;
    if (filename != null) result['filename'] = filename;
    if (mediaType != null) result['media_type'] = mediaType;
    if (format != null) result['format'] = format;
    if (lastModifiedTime != null) {
      result['lastmod_time'] =
          lastModifiedTime!.toUtc().millisecondsSinceEpoch ~/ 1000;
    }
    if (data != null) result['data'] = data!.toJson();
    if (byteCount != null) result['byte_count'] = byteCount;
    return result;
  }
}
