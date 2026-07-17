import 'package:meeting_place_core/meeting_place_core.dart'
    show ChannelActivityType;

/// Known `ChannelActivity.type` string constants for call-related activities.
///
/// These extend the core [ChannelActivityType] constants with Matrix/LiveKit
/// call signalling values that are produced and consumed exclusively by the
/// matrix transport layer.
abstract final class CallChannelActivityType {
  /// Signals that the sender has initiated a video call on this channel.
  static const String callInviteVideo = 'call-invite-video';

  /// Signals that the sender has initiated an audio-only call on this channel.
  static const String callInviteAudio = 'call-invite-audio';

  /// Signals that the recipient has declined a call before answering.
  static const String callDecline = 'call-decline';
}
