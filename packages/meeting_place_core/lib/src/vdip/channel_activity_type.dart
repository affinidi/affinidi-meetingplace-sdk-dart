/// Known `ChannelActivity.type` string constants.
///
/// The control-plane server treats this field as a free-form string and passes
/// it through unchanged. These constants establish the canonical values used
/// by SDK producers and consumers so literal strings are never scattered across
/// the codebase.
abstract final class ChannelActivityType {
  static const String chatActivity = 'chat-activity';
  static const String channelInauguration = 'channel-inauguration';

  /// Signals that the sender has initiated a video/audio call on this channel.
  ///
  /// Triggers lazy on-demand activation of the callee's Matrix session and
  /// emits an `IncomingCallSignal` on the SDK's `incomingCallSignals` stream.
  /// Does not increment the badge count.
  static const String callInvite = 'call-invite';

  /// Signals that the recipient (callee) has declined a call before answering.
  static const String callDecline = 'call-decline';

  static const String vdipRequestIssuance = 'vdip-request-issuance';
  static const String vdipIssuedCredentials = 'vdip-issued-credentials';
}
