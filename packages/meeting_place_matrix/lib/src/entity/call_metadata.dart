import 'package:meeting_place_chat/meeting_place_chat.dart';

import '../call/call_media_type.dart';
import 'call_participation.dart';
import 'call_status.dart';

/// Call metadata layered on top of a generic [ChatAttachment].
///
/// A call chat item is a generic attachment distinguished by a `media_kind`
/// marker stored in [ChatAttachment.metadata], plus the call media type, the
/// current [CallStatus] and the local participation duration. Keeping this off
/// [ChatAttachment] keeps the attachment a general type and lets call items add
/// their own metadata view without changing the shared type, mirroring
/// `VoiceMessageMetadata`.
///
/// Group calls additionally carry a [CallParticipation] block; a `null`
/// participation means a 1:1 call.
class CallMetadata {
  CallMetadata({
    required this.mediaType,
    required this.status,
    required this.callId,
    this.participation,
    int? durationMs,
  }) : durationMs = _validateDurationMs(durationMs);

  /// Reads call metadata from [attachment], or `null` when it is not a call.
  static CallMetadata? maybeOf(ChatAttachment attachment) {
    final metadata = attachment.metadata;
    if (metadata == null || metadata[_mediaKindKey] != _callKind) return null;
    final mediaType = _mediaTypeFromMetadata(metadata[_callMediaTypeKey]);
    if (mediaType == null) return null;
    final status = _statusFromMetadata(metadata[_statusKey]);
    if (status == null) return null;
    final callIdValue = metadata[_callIdKey];
    if (callIdValue != null && callIdValue is! String) return null;
    return CallMetadata(
      mediaType: mediaType,
      status: status,
      callId: (callIdValue as String?) ?? '',
      participation: CallParticipation.fromMap(metadata[_participationKey]),
      durationMs: _durationFromMetadata(metadata[_durationMsKey]),
    );
  }

  /// Whether [attachment] is a call.
  static bool isCall(ChatAttachment attachment) =>
      attachment.metadata?[_mediaKindKey] == _callKind;

  /// Builds a call [ChatAttachment] carrying only call metadata (no bytes).
  static ChatAttachment buildAttachment({
    required CallMediaType mediaType,
    required CallStatus status,
    required String id,
    required String callId,
    CallParticipation? participation,
    int? durationMs,
  }) {
    final call = CallMetadata(
      mediaType: mediaType,
      status: status,
      callId: callId,
      participation: participation,
      durationMs: durationMs,
    );
    return ChatAttachment(id: id, metadata: call.toMetadata());
  }

  /// Metadata key marking the attachment media kind.
  static const _mediaKindKey = 'media_kind';

  /// Identifies an attachment as a call.
  static const _callKind = 'call';

  /// Metadata key for the call media type.
  static const _callMediaTypeKey = 'call_media_type';

  /// Metadata key for the call status.
  static const _statusKey = 'call_status';

  /// Metadata key for the transport call session ID.
  static const _callIdKey = 'call_id';

  /// Metadata key for the local participation duration in milliseconds.
  static const _durationMsKey = 'duration_ms';

  /// Metadata key for the group participation block.
  static const _participationKey = 'call_participation';

  /// The call media type (audio or video).
  final CallMediaType mediaType;

  /// The current call status for the local party.
  final CallStatus status;

  /// The transport call session ID (format: `roomId@microsecondsSinceEpoch`).
  ///
  /// Stable join-key linking this chat item to the call-log entry for this
  /// session. Matches across both sides of the call.
  final String callId;

  /// Local participation duration in milliseconds, when known.
  final int? durationMs;

  /// Group participation summary. `null` for a 1:1 call.
  final CallParticipation? participation;

  /// Serializes this call metadata into a generic [ChatAttachment.metadata]
  /// map.
  Map<String, dynamic> toMetadata() => {
    _mediaKindKey: _callKind,
    _callMediaTypeKey: mediaType.name,
    _statusKey: status.name,
    _callIdKey: callId,
    if (durationMs != null) _durationMsKey: durationMs,
    if (participation != null) _participationKey: participation!.toMap(),
  };

  /// Returns a copy with the given fields replaced.
  CallMetadata copyWith({
    CallStatus? status,
    int? durationMs,
    CallParticipation? participation,
  }) => CallMetadata(
    mediaType: mediaType,
    status: status ?? this.status,
    callId: callId,
    participation: participation ?? this.participation,
    durationMs: durationMs ?? this.durationMs,
  );

  static int? _validateDurationMs(int? durationMs) {
    if (durationMs != null && durationMs < 0) {
      throw ArgumentError.value(durationMs, 'durationMs', 'must be >= 0');
    }
    return durationMs;
  }

  static CallMediaType? _mediaTypeFromMetadata(Object? value) {
    if (value is! String) return null;
    for (final type in CallMediaType.values) {
      if (type.name == value) return type;
    }
    return null;
  }

  static CallStatus? _statusFromMetadata(Object? value) {
    if (value is! String) return null;
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
