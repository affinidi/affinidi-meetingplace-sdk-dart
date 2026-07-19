import '../../../../call/call_media_type.dart';

/// Emitted on `AudioVideoCallPlugin.incomingCalls` when a peer
/// calls you.
class IncomingAudioVideoCallEvent {
  const IncomingAudioVideoCallEvent({
    required this.callId,
    required this.callerPermanentChannelDid,
    required this.otherPartyPermanentChannelDid,
    required this.mediaType,
    required this.invitedAt,
    this.ownPermanentChannelDid,
    this.roomId,
  });

  /// Identifier for this call.
  ///
  /// Uses the transport call session ID when available, but may fall back to a
  /// Matrix room ID or caller DID when transport metadata is not yet ready.
  final String callId;

  /// The caller's permanent channel DID (stable identifier, not ephemeral).
  ///
  /// Identifies the peer initiating the call.
  final String callerPermanentChannelDid;

  /// The peer's permanent channel DID (stable identifier, not ephemeral).
  final String otherPartyPermanentChannelDid;

  /// Whether the call carries video or is audio-only.
  final CallMediaType mediaType;

  /// Time the incoming call signal was surfaced locally.
  final DateTime invitedAt;

  /// The recipient's channel DID that received the call signal when known.
  final String? ownPermanentChannelDid;

  /// Matrix room ID when known; enables lifecycle observation in group calls
  /// before full transport metadata is stable.
  final String? roomId;
}
