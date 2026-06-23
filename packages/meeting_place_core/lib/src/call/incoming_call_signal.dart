import '../call/call_media_type.dart';

class IncomingCallSignal {
  /// Emitted on `MeetingPlaceCoreSDK.incomingCallSignals` when a
  /// `ChannelActivity(type: 'call-invite')` event is received from the control
  /// plane.
  ///
  /// This is a pure-Dart, transport-agnostic signal. The plugin layer
  /// (`MeetingPlaceLiveKitCallPlugin`) subscribes to this stream and calls
  /// `activateIncomingCall` to lazily bring up the Matrix session and emit an
  /// `IncomingCallEvent` on the plugin's `incomingCalls` broadcast stream.
  const IncomingCallSignal({
    required this.ownChannelDid,
    this.mediaType = CallMediaType.video,
  });

  /// The callee's own permanent channel DID, matching
  /// `Channel.permanentChannelDid` on the receiving device.
  ///
  /// The control plane delivers this via `ChannelActivity.did` in the pending
  /// notification. The plugin uses it to look up the local channel record,
  /// derive the caller's DID from `Channel.otherPartyPermanentChannelDid`,
  /// and call `activateIncomingCall`.
  final String ownChannelDid;

  /// Whether the call carries video or is audio-only.
  ///
  /// Derived from the `mpx.call.invite` Matrix room event sent by the caller
  /// alongside the `call-invite` nudge.
  final CallMediaType mediaType;
}
