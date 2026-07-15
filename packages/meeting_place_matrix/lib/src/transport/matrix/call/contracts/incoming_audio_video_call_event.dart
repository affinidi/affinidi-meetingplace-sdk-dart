import '../../../../call/call_media_type.dart';

/// Emitted on `AudioVideoCallPlugin.incomingCalls` when the other party
/// calls you.
class IncomingAudioVideoCallEvent {
  const IncomingAudioVideoCallEvent({
    required this.callId,
    required this.callerPermanentChannelDid,
    required this.otherPartyPermanentChannelDid,
    required this.mediaType,
  });

  /// The transport call session ID for this incoming call.
  final String callId;

  /// The caller's permanent channel DID (stable identifier, not ephemeral).
  ///
  /// This identifies the remote party initiating the call.
  final String callerPermanentChannelDid;

  /// The other party's permanent channel DID (stable identifier,
  /// not ephemeral).
  final String otherPartyPermanentChannelDid;

  /// Whether the call carries video or is audio-only.
  final CallMediaType mediaType;
}
