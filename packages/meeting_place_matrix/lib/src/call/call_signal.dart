import 'call_media_type.dart';

sealed class CallSignal {
  const CallSignal({required this.ownChannelDid});

  /// The local permanent channel DID that received this signal,
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
  const CallDeclineSignal({required super.ownChannelDid});
}
