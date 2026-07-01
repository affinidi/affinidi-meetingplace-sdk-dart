import 'package:didcomm/didcomm.dart' show Attachment, AttachmentData;

import 'chat_attachment_data.dart';

export 'chat_attachment_data.dart';

/// Public typedef for the core SDK attachment type (`Attachment` from
/// `package:didcomm`) so consumers don't need a direct didcomm dependency.
typedef CoreAttachment = Attachment;

/// A transport-agnostic attachment for chat messages.
///
/// [ChatAttachment] replaces the DIDComm-specific `Attachment` type on the
/// public SDK boundary. The SDK converts to and from the wire format
/// internally. The JSON serialization is wire-compatible with DIDComm so that
/// persisted messages remain readable.
class ChatAttachment {
  ChatAttachment({
    required this.id,
    this.description,
    this.filename,
    this.mediaType,
    this.format,
    this.lastModifiedTime,
    this.data,
    this.byteCount,
    this.transportId,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata == null ? null : Map.unmodifiable(metadata);

  /// Deserialises a [ChatAttachment] from a JSON map.
  ///
  /// The key names match the DIDComm wire format so that persisted
  /// messages remain fully round-trippable.
  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Missing or invalid attachment id');
    }

    return ChatAttachment(
      id: id,
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
      transportId: json['transport_id'] as String?,
      metadata: _metadataFromJson(json['metadata']),
    );
  }

  /// Unique identifier for the attachment.
  final String id;

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

  /// Transport-level reference for downloading this attachment's bytes.
  ///
  /// For Matrix hosted media, this is the event id of the `m.room.message`
  /// event carrying the single file. For DIDComm inline attachments this is
  /// `null` because the bytes ride inside [data]. Populated by the sender
  /// after upload completes and by the receiver from the originating
  /// transport event.
  String? transportId;

  /// Extensible metadata for media kinds that need more than a MIME type
  /// (JSON key: `metadata`).
  ///
  /// The map is opaque to [ChatAttachment]; typed views such as
  /// `VoiceMessageMetadata` own their own keys. `null` for plain attachments.
  final Map<String, dynamic>? metadata;

  /// Serialises this [ChatAttachment] to a JSON map.
  ///
  /// The key names match the DIDComm wire format so that persisted
  /// messages remain fully round-trippable.
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    result['id'] = id;
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
    if (transportId != null) result['transport_id'] = transportId;
    if (metadata != null) result['metadata'] = metadata;
    return result;
  }

  static Map<String, dynamic>? _metadataFromJson(Object? value) {
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException('Invalid attachment metadata');
    }
    return Map<String, dynamic>.from(value);
  }
}

/// Converts a [ChatAttachment] to the core SDK [CoreAttachment] type.
extension ChatAttachmentCoreConversion on ChatAttachment {
  CoreAttachment toCoreAttachment() => CoreAttachment(
    id: id,
    description: description,
    filename: filename,
    mediaType: mediaType,
    format: format,
    lastModifiedTime: lastModifiedTime,
    data: data != null
        ? AttachmentData(
            jws: data!.jws,
            hash: data!.hash,
            links: data!.links,
            base64: data!.base64,
            json: data!.json,
          )
        : AttachmentData(),
    byteCount: byteCount,
  );
}

/// Converts a [CoreAttachment] to a [ChatAttachment].
extension CoreAttachmentToChatAttachment on CoreAttachment {
  ChatAttachment toChatAttachment() {
    final id = this.id;
    if (id == null || id.isEmpty) {
      throw const FormatException(
        'CoreAttachment id must not be null or empty',
      );
    }

    return ChatAttachment(
      id: id,
      description: description,
      filename: filename,
      mediaType: mediaType,
      format: format,
      lastModifiedTime: lastModifiedTime,
      data: data == null
          ? null
          : ChatAttachmentData(
              jws: data!.jws,
              hash: data!.hash,
              links: data!.links,
              base64: data!.base64,
              json: data!.json,
            ),
      byteCount: byteCount,
    );
  }
}
