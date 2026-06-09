import 'package:meeting_place_core/meeting_place_core.dart';

import 'chat_attachment.dart';

/// Voice-message metadata layered on top of a generic [ChatAttachment].
///
/// A voice note is a generic audio attachment distinguished by a `media_kind`
/// marker stored in [ChatAttachment.metadata], plus a duration and an optional
/// normalized waveform. Keeping this off [ChatAttachment] keeps the attachment
/// a general media file and lets new media kinds add their own metadata view
/// without changing the shared type.
class VoiceMessageMetadata {
  VoiceMessageMetadata({int? durationMs, List<int>? waveform})
    : durationMs = _validateDurationMs(durationMs),
      waveform = _validateWaveform(waveform);

  /// Reads voice metadata from [attachment], or `null` when it is not a voice
  /// note.
  static VoiceMessageMetadata? of(ChatAttachment attachment) {
    final metadata = attachment.metadata;
    if (metadata == null || metadata[mediaKindKey] != voiceKind) return null;
    return VoiceMessageMetadata(
      durationMs: _durationFromMetadata(metadata[durationMsKey]),
      waveform: _waveformFromMetadata(metadata[waveformKey]),
    );
  }

  /// Whether [attachment] is a voice note.
  static bool isVoice(ChatAttachment attachment) =>
      attachment.metadata?[mediaKindKey] == voiceKind;

  /// Builds a voice-message [ChatAttachment] with inline base64 audio bytes.
  static ChatAttachment buildAttachment({
    required String base64,
    required int durationMs,
    String? id,
    String? description,
    String? filename,
    String? mediaType,
    String? format,
    DateTime? lastModifiedTime,
    int? byteCount,
    List<int> waveform = const [],
  }) {
    if (base64.isEmpty) {
      throw ArgumentError.value(base64, 'base64', 'must not be empty');
    }
    final effectiveMediaType = mediaType ?? defaultMediaType;
    if (!effectiveMediaType.toLowerCase().startsWith('audio/')) {
      throw ArgumentError.value(
        effectiveMediaType,
        'mediaType',
        'must be audio/*',
      );
    }
    final voice = VoiceMessageMetadata(
      durationMs: durationMs,
      waveform: waveform,
    );
    return ChatAttachment(
      id: id,
      description: description,
      filename: filename,
      mediaType: effectiveMediaType,
      format: format,
      lastModifiedTime: lastModifiedTime,
      data: ChatAttachmentData(base64: base64),
      byteCount: byteCount,
      metadata: voice.toMetadata(),
    );
  }

  /// Metadata key marking the attachment media kind.
  static const mediaKindKey = 'media_kind';

  /// [mediaKindKey] value identifying a voice note.
  static const voiceKind = 'voice';

  /// Metadata key for the voice duration in milliseconds.
  static const durationMsKey = 'duration_ms';

  /// Metadata key for the normalized waveform samples.
  static const waveformKey = 'waveform';

  /// Minimum normalized waveform sample value.
  static const waveformMinSample = 0;

  /// Maximum normalized waveform sample value.
  static const waveformMaxSample = 100;

  /// Default MIME type used when a voice attachment omits one.
  static final defaultMediaType = AttachmentMediaType.audioMp4.value;

  /// Voice duration in milliseconds, when known.
  final int? durationMs;

  /// Normalized waveform samples in the 0-100 range, when present.
  final List<int>? waveform;

  /// Serializes this voice metadata into a generic [ChatAttachment.metadata]
  /// map.
  Map<String, dynamic> toMetadata() => {
    mediaKindKey: voiceKind,
    if (durationMs != null) durationMsKey: durationMs,
    if (waveform != null) waveformKey: waveform,
  };

  static int? _validateDurationMs(int? durationMs) {
    if (durationMs != null && durationMs < 0) {
      throw ArgumentError.value(durationMs, 'durationMs', 'must be >= 0');
    }
    return durationMs;
  }

  static List<int>? _validateWaveform(List<int>? waveform) {
    if (waveform == null) return null;
    for (final sample in waveform) {
      if (sample < waveformMinSample || sample > waveformMaxSample) {
        throw ArgumentError.value(sample, 'waveform', 'must be 0-100');
      }
    }
    return List.unmodifiable(waveform);
  }

  static int? _durationFromMetadata(Object? value) {
    if (value is int && value >= 0) return value;
    return null;
  }

  static List<int>? _waveformFromMetadata(Object? value) {
    if (value is! List) return null;
    final samples = <int>[];
    for (final sample in value) {
      if (sample is! int ||
          sample < waveformMinSample ||
          sample > waveformMaxSample) {
        return null;
      }
      samples.add(sample);
    }
    return List.unmodifiable(samples);
  }
}
