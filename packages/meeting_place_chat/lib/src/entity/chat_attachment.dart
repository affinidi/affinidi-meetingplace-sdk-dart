import 'chat_attachment_data.dart';

export 'chat_attachment_data.dart';

/// App-facing media kind for attachments that need behavior beyond MIME type.
enum AttachmentMediaKind {
  /// Short voice message rendered as an inline voice note.
  voice('voice');

  const AttachmentMediaKind(this.value);

  /// Serialized value used in JSON and Matrix custom metadata.
  final String value;
}

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
    this.transportId,
    this.mediaKind,
    int? durationMs,
    List<int>? waveform,
  }) : durationMs = _validateDurationMs(durationMs),
       waveform = _validateWaveform(waveform);

  /// Creates a voice-message attachment with inline base64 audio bytes.
  factory ChatAttachment.voiceMessage({
    required String base64,
    required int durationMs,
    String? id,
    String? description,
    String? filename,
    String mediaType = defaultVoiceMediaType,
    String? format,
    DateTime? lastModifiedTime,
    int? byteCount,
    List<int> waveform = const [],
  }) {
    if (base64.isEmpty) {
      throw ArgumentError.value(base64, 'base64', 'must not be empty');
    }
    if (!mediaType.toLowerCase().startsWith('audio/')) {
      throw ArgumentError.value(mediaType, 'mediaType', 'must be audio/*');
    }
    return ChatAttachment(
      id: id,
      description: description,
      filename: filename,
      mediaType: mediaType,
      format: format,
      lastModifiedTime: lastModifiedTime,
      data: ChatAttachmentData(base64: base64),
      byteCount: byteCount,
      mediaKind: AttachmentMediaKind.voice,
      durationMs: durationMs,
      waveform: waveform,
    );
  }

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
      transportId: json['transport_id'] as String?,
      mediaKind: _mediaKindFromJson(json['media_kind']),
      durationMs: _durationMsFromJson(json['duration_ms']),
      waveform: _waveformFromJson(json['waveform']),
    );
  }

  /// Default MIME type used by [ChatAttachment.voiceMessage].
  static const defaultVoiceMediaType = 'audio/mp4';

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

  /// Transport-level reference for downloading this attachment's bytes.
  ///
  /// For Matrix hosted media, this is the event id of the `m.room.message`
  /// event carrying the single file. For DIDComm inline attachments this is
  /// `null` because the bytes ride inside [data]. Populated by the sender
  /// after upload completes and by the receiver from the originating
  /// transport event.
  String? transportId;

  /// Optional behavior hint beyond MIME type (JSON key: `media_kind`).
  final AttachmentMediaKind? mediaKind;

  /// Optional media duration in milliseconds (JSON key: `duration_ms`).
  final int? durationMs;

  /// Optional normalized waveform samples in the 0-100 range.
  final List<int>? waveform;

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
    if (transportId != null) result['transport_id'] = transportId;
    if (mediaKind != null) result['media_kind'] = mediaKind!.value;
    if (durationMs != null) result['duration_ms'] = durationMs;
    if (waveform != null) result['waveform'] = waveform;
    return result;
  }

  static int? _validateDurationMs(int? durationMs) {
    if (durationMs != null && durationMs < 0) {
      throw ArgumentError.value(durationMs, 'durationMs', 'must be >= 0');
    }
    return durationMs;
  }

  static List<int>? _validateWaveform(List<int>? waveform) {
    if (waveform == null) return null;
    for (final sample in waveform) {
      if (sample < 0 || sample > 100) {
        throw ArgumentError.value(sample, 'waveform', 'must be 0-100');
      }
    }
    return List.unmodifiable(waveform);
  }

  static AttachmentMediaKind? _mediaKindFromJson(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Invalid attachment media_kind');
    }
    return switch (value) {
      'voice' => AttachmentMediaKind.voice,
      _ => throw const FormatException('Invalid attachment media_kind'),
    };
  }

  static int? _durationMsFromJson(Object? value) {
    if (value == null) return null;
    if (value is! int || value < 0) {
      throw const FormatException('Invalid attachment duration_ms');
    }
    return value;
  }

  static List<int>? _waveformFromJson(Object? value) {
    if (value == null) return null;
    if (value is! List) {
      throw const FormatException('Invalid attachment waveform');
    }
    final samples = <int>[];
    for (final sample in value) {
      if (sample is! int || sample < 0 || sample > 100) {
        throw const FormatException('Invalid attachment waveform');
      }
      samples.add(sample);
    }
    return List.unmodifiable(samples);
  }
}
