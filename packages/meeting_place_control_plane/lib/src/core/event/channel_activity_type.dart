/// Known `ChannelActivity.type` string constants.
///
/// The control-plane server treats this field as a free-form string and passes
/// it through unchanged. These constants establish the canonical values used
/// by SDK producers and consumers so literal strings are never scattered across
/// the codebase.
abstract final class ChannelActivityType {
  static const chatActivity = 'chat-activity';
  static const channelInauguration = 'channel-inauguration';

  /// Signals that the sender has initiated a video call on this channel.
  ///
  /// Triggers lazy on-demand activation of the callee's Matrix session and
  /// emits an `IncomingCallSignal` on the SDK's `incomingCallSignals` stream.
  /// Does not increment the badge count.
  static const callInviteVideo = 'call-invite-video';

  /// Signals that the recipient (callee) has declined a call before answering.
  ///
  /// Sent by the callee to the caller's channel DID. The caller reacts by
  /// emitting `AudioVideoCallStatus.declined` on the active session.
  static const callDecline = 'call-decline';
}
