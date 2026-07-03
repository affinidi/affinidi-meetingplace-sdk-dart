import 'package:meeting_place_chat/meeting_place_chat.dart';

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

  /// Stores the caller-supplied [ChatAttachment.id] for media events so the
  /// receiver can preserve attachment identity across the Matrix transport.
  static const attachmentId = 'mp_attachment_id';

  /// Stores the [ChatAttachment.format] for media events so the receiver
  /// can reconstruct the original format of each attachment.
  static const attachmentFormat = 'mp_attachment_format';

  /// Embeds call item metadata in `mpx.call.item` room events so the
  /// receiver can reconstruct the [ChatAttachment] without a file download.
  static const callMetadata = 'mp_call_metadata';
}

/// Matrix-specific helpers for parsing and inspecting media attachments
/// carried inside Matrix room events.
///
/// All methods are static; this class exists purely to scope the helpers to
/// the Matrix transport layer.
class MatrixMediaAttachments {
  MatrixMediaAttachments._();

  /// MSC3245: content-level voice marker (`org.matrix.msc3245.voice: {}`).
  static const voiceContentKey = 'org.matrix.msc3245.voice';

  /// MSC1767: content-level audio metadata
  /// (`org.matrix.msc1767.audio: {duration, waveform}`).
  static const audioContentKey = 'org.matrix.msc1767.audio';

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
    if (msgtype == null) return const <ChatAttachment>[];

    if (!_mediaMsgTypes.contains(msgtype)) {
      return const [];
    }

    final info = _mapValue(content['info']);
    final filename =
        _stringValue(content['filename']) ?? _stringValue(content['body']);
    final mimeType = _stringValue(info?['mimetype']);
    final sizeValue = info?['size'];
    final size = sizeValue is int ? sizeValue : null;
    final attachmentId = _stringValue(content[MatrixEventField.attachmentId]);
    final format = _stringValue(content[MatrixEventField.attachmentFormat]);
    if (attachmentId == null || attachmentId.isEmpty) {
      throw const FormatException('Matrix media attachment id is required');
    }

    return [
      ChatAttachment(
        id: attachmentId,
        filename: filename,
        mediaType: mimeType,
        format: format,
        byteCount: size,
        metadata: _voiceMetadata(content, info),
      ),
    ];
  }

  /// Reads voice metadata from content-level MSC keys, or `null` for generic
  /// media.
  static Map<String, dynamic>? _voiceMetadata(
    Map<String, dynamic> content,
    Map<String, dynamic>? info,
  ) {
    if (content[voiceContentKey] == null) return null;
    final audio = _mapValue(content[audioContentKey]);
    return VoiceMessageMetadata(
      durationMs: _durationValue(audio?['duration'] ?? info?['duration']),
      waveform: _waveformValue(audio?['waveform']),
    ).toMetadata();
  }

  /// Builds the content-level extra fields for outgoing voice attachments.
  ///
  /// Returns an empty map for non-voice attachments. For voice, returns an
  /// `info` override (mimetype + size + duration) plus the MSC3245 voice marker
  /// and MSC1767 audio block at the top level of the Matrix event content.
  static Map<String, dynamic> buildVoiceContent(
    ChatAttachment attachment, {
    required String contentType,
    required int sizeBytes,
  }) {
    final voice = VoiceMessageMetadata.of(attachment);
    if (voice == null) return const {};

    final durationMs = voice.durationMs;
    if (durationMs == null) {
      throw ArgumentError.value(
        durationMs,
        'durationMs',
        'Voice attachments require durationMs',
      );
    }

    final audio = <String, dynamic>{'duration': durationMs};
    final waveform = voice.waveform;
    if (waveform != null) audio['waveform'] = waveform;

    return {
      'info': {
        'mimetype': contentType,
        'size': sizeBytes,
        'duration': durationMs,
      },
      voiceContentKey: <String, dynamic>{},
      audioContentKey: audio,
    };
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

  static int? _durationValue(Object? value) {
    if (value is int && value >= 0) return value;
    return null;
  }

  static List<int>? _waveformValue(Object? value) {
    if (value is! List) return null;
    final samples = <int>[];
    for (final sample in value) {
      if (sample is! int ||
          sample < VoiceMessageMetadata.waveformMinSample ||
          sample > VoiceMessageMetadata.waveformMaxSample) {
        return null;
      }
      samples.add(sample);
    }
    return List.unmodifiable(samples);
  }

  static Map<String, dynamic>? _mapValue(Object? value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }
}
