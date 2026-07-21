import 'package:meeting_place_core/meeting_place_core.dart' show ContactCard;

import './audio_video_call_error_code.dart';
import './audio_video_call_participant.dart';
import './audio_video_call_status.dart';
import './call_role.dart';

/// All state that an `AudioVideoCallSession` publishes for the presentation
/// layer to observe via `AudioVideoCallSession.state`.
///
/// UI-only fields (mic/camera toggle display state, permission errors) live in
/// the app-layer screen state, not here.
class AudioVideoCallState {
  const AudioVideoCallState({
    this.status = AudioVideoCallStatus.idle,
    this.participants = const [],
    this.participantContactCardsByDid = const {},
    this.errorCode,
    this.ownRole,
    this.callId,
    this.callStartedAt,
  });

  final AudioVideoCallStatus status;
  final List<AudioVideoCallParticipant> participants;
  final Map<String, ContactCard> participantContactCardsByDid;

  /// Non-null only when [status] is [AudioVideoCallStatus.error].
  final AudioVideoCallErrorCode? errorCode;

  /// This device's role in the call, or `null` until the call has progressed
  /// far enough to determine it.
  ///
  /// Resolved from the Matrix room's call membership at join time:
  /// [CallRole.caller] when no active call membership existed before this
  /// device published its own, [CallRole.recipient] when a call was already in
  /// progress.
  ///
  /// Consumers use this to attribute call-start side effects (e.g. emitting a
  /// call chat item) to the caller only.
  final CallRole? ownRole;

  /// The transport call session ID (format: `roomId@microsecondsSinceEpoch`).
  ///
  /// Set when the call session is prepared. Use this to embed in
  /// `CallMetadata` so call chat items can be joined to call-log entries.
  /// `null` until the session is established.
  final String? callId;

  /// Shared call start time, derived from the callId timestamp.
  ///
  /// Consumers render duration as `now - callStartedAt`, so both sides show
  /// the same elapsed time without extra signalling. `null` until the callId
  /// is resolved.
  final DateTime? callStartedAt;

  /// The default initial state: idle, no participants, no error.
  static const initial = AudioVideoCallState();

  AudioVideoCallState copyWith({
    AudioVideoCallStatus? status,
    List<AudioVideoCallParticipant>? participants,
    Map<String, ContactCard>? participantContactCardsByDid,
    AudioVideoCallErrorCode? errorCode,
    bool clearErrorCode = false,
    CallRole? ownRole,
    String? callId,
    DateTime? callStartedAt,
  }) {
    return AudioVideoCallState(
      status: status ?? this.status,
      participants: participants ?? this.participants,
      participantContactCardsByDid:
          participantContactCardsByDid ?? this.participantContactCardsByDid,
      errorCode: clearErrorCode ? null : (errorCode ?? this.errorCode),
      ownRole: ownRole ?? this.ownRole,
      callId: callId ?? this.callId,
      callStartedAt: callStartedAt ?? this.callStartedAt,
    );
  }
}
