/// Known `ChannelActivity.type` string constants.
///
/// The control-plane server treats this field as a free-form string and passes
/// it through unchanged. These constants establish the canonical values used
/// by SDK producers and consumers so literal strings are never scattered across
/// the codebase.
abstract final class ChannelActivityType {
  /// Signals a chat message or other chat-related activity on the channel.
  static const String chatActivity = 'chat-activity';

  /// Signals that the channel has been inaugurated (fully established
  /// between both parties).
  static const String channelInauguration = 'channel-inauguration';

  /// Signals that the sender requests VDIP credential issuance.
  static const String vdipRequestIssuance = 'vdip-request-issuance';

  /// Signals that VDIP credentials were issued and are available.
  static const String vdipIssuedCredentials = 'vdip-issued-credentials';
}
