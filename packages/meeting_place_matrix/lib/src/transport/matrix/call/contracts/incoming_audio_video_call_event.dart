import '../../../../call/call_media_type.dart';

/// Emitted on `AudioVideoCallPlugin.incomingCalls` when the other party
/// calls you.
class IncomingAudioVideoCallEvent {
  const IncomingAudioVideoCallEvent({
    required this.callerPermanentChannelDid,
    required this.otherPartyPermanentChannelDid,
    required this.mediaType,
  });

  /// The caller's permanent channel DID (stable identifier, not ephemeral).
  ///
  /// This identifies the remote party initiating the call, not the transport
  /// call session. Use with `AudioVideoCallPlugin.acceptCall` or
  /// `AudioVideoCallPlugin.declineCall` to act on this specific call.
  final String callerPermanentChannelDid;

  /// The other party's permanent channel DID (stable identifier,
  /// not ephemeral).
  final String otherPartyPermanentChannelDid;

  /// Whether the call carries video or is audio-only.
  final CallMediaType mediaType;
}
