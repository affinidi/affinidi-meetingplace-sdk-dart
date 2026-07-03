import '../../../../call/call_media_type.dart';

/// Emitted on `AudioVideoCallPlugin.incomingCalls` when the other party
/// calls you.
class IncomingAudioVideoCallEvent {
  const IncomingAudioVideoCallEvent({
    required this.callId,
    required this.otherPartyChannelDid,
    required this.mediaType,
  });

  /// The MatrixRTC call session identifier.
  ///
  /// Pass this to `AudioVideoCallPlugin.acceptCall` or
  /// `AudioVideoCallPlugin.declineCall` to act on this specific call.
  final String callId;

  /// The other party's channel DID.
  final String otherPartyChannelDid;

  /// Whether the call carries video or is audio-only.
  final CallMediaType mediaType;
}
