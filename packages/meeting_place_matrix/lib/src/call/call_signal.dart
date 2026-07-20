import 'call_media_type.dart';

sealed class CallSignal {
  const CallSignal({required this.ownChannelDid});

  /// The self permanent channel DID that received this signal,
  /// matching `Channel.permanentChannelDid` on the receiving device.
  final String ownChannelDid;
}

final class IncomingCallSignal extends CallSignal {
  const IncomingCallSignal({
    required super.ownChannelDid,
    this.mediaType = CallMediaType.video,
  });

  /// Whether the call carries video or is audio-only.
  final CallMediaType mediaType;
}

final class CallDeclineSignal extends CallSignal {
  const CallDeclineSignal({
    required super.ownChannelDid,
    this.otherPartyPermanentChannelDid,
  });

  /// The cancelling peer's permanent channel DID when available.
  ///
  /// Group call decline notifications fan out through the group channel, so
  /// [ownChannelDid] identifies the receiving channel rather than the caller.
  /// Carrying the caller DID lets recipients map the cancel back to the
  /// ringing peer.
  final String? otherPartyPermanentChannelDid;
}
