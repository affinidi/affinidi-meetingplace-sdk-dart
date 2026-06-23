import 'package:meeting_place_core/meeting_place_core.dart';

import 'chat_attachment.dart';

/// The lifecycle state of a call chat item, as rendered to the local party.
///
/// The same call produces one chat item per side. The status is updated in
/// place (via a message edit) as the call progresses, so a single item moves
/// through these states rather than emitting a new item per transition.
enum CallStatus {
  /// Outgoing call, waiting for the other party to answer (caller side).
  calling,

  /// Caller side: the remote device is ringing. Transitions from [calling].
  ringing,

  /// A participant has joined; the call is active.
  inProgress,

  /// The local party left the call; shows the local participation duration.
  ended,

  /// The other party started and ended the call before it was answered.
  /// Shown on the receiver side.
  missed,

  /// Caller side: call ended without answer — either the receiver timed out
  /// or actively declined. Both cases show "Not answered" in the UI.
  declined,
}

/// Call metadata layered on top of a generic [ChatAttachment].
///
/// A call chat item is a generic attachment distinguished by a `media_kind`
/// marker stored in [ChatAttachment.metadata], plus the call media type, the
/// current [CallStatus] and the local participation duration. Keeping this off
/// [ChatAttachment] keeps the attachment a general type and lets call items add
/// their own metadata view without changing the shared type, mirroring
/// `VoiceMessageMetadata`.
class CallMetadata {
  CallMetadata({required this.mediaType, required this.status, int? durationMs})
    : durationMs = _validateDurationMs(durationMs);

  /// Reads call metadata from [attachment], or `null` when it is not a call.
  static CallMetadata? maybeOf(ChatAttachment attachment) {
    final metadata = attachment.metadata;
    if (metadata == null || metadata[mediaKindKey] != callKind) return null;
    final mediaType = _mediaTypeFromMetadata(metadata[callMediaTypeKey]);
    final status = _statusFromMetadata(metadata[statusKey]);
    if (mediaType == null || status == null) return null;
    return CallMetadata(
      mediaType: mediaType,
      status: status,
      durationMs: _durationFromMetadata(metadata[durationMsKey]),
    );
  }

  /// Whether [attachment] is a call.
  static bool isCall(ChatAttachment attachment) =>
      attachment.metadata?[mediaKindKey] == callKind;

  /// Builds a call [ChatAttachment] carrying only call metadata (no bytes).
  static ChatAttachment buildAttachment({
    required CallMediaType mediaType,
    required CallStatus status,
    int? durationMs,
    String? id,
  }) {
    final call = CallMetadata(
      mediaType: mediaType,
      status: status,
      durationMs: durationMs,
    );
    return ChatAttachment(id: id, metadata: call.toMetadata());
  }

  /// Metadata key marking the attachment media kind.
  static const mediaKindKey = 'media_kind';

  /// [mediaKindKey] value identifying a call.
  static const callKind = 'call';

  /// Metadata key for the call media type.
  static const callMediaTypeKey = 'call_media_type';

  /// Metadata key for the call status.
  static const statusKey = 'call_status';

  /// Metadata key for the local participation duration in milliseconds.
  static const durationMsKey = 'duration_ms';

  /// The call media type (audio or video).
  final CallMediaType mediaType;

  /// The current call status for the local party.
  final CallStatus status;

  /// Local participation duration in milliseconds, when known.
  final int? durationMs;

  /// Serializes this call metadata into a generic [ChatAttachment.metadata]
  /// map.
  Map<String, dynamic> toMetadata() => {
    mediaKindKey: callKind,
    callMediaTypeKey: mediaType.name,
    statusKey: status.name,
    if (durationMs != null) durationMsKey: durationMs,
  };

  /// Returns a copy with the given fields replaced.
  CallMetadata copyWith({CallStatus? status, int? durationMs}) => CallMetadata(
    mediaType: mediaType,
    status: status ?? this.status,
    durationMs: durationMs ?? this.durationMs,
  );

  static int? _validateDurationMs(int? durationMs) {
    if (durationMs != null && durationMs < 0) {
      throw ArgumentError.value(durationMs, 'durationMs', 'must be >= 0');
    }
    return durationMs;
  }

  static CallMediaType? _mediaTypeFromMetadata(Object? value) {
    for (final type in CallMediaType.values) {
      if (type.name == value) return type;
    }
    return null;
  }

  static CallStatus? _statusFromMetadata(Object? value) {
    for (final status in CallStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }

  static int? _durationFromMetadata(Object? value) {
    if (value is int && value >= 0) return value;
    return null;
  }
}
