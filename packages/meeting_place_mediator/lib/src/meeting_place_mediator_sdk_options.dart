class MeetingPlaceMediatorSDKOptions {
  const MeetingPlaceMediatorSDKOptions({
    this.secondsBeforeExpiryReauthenticate = 60,
    this.websocketPingInterval = 30,
    this.maxRetryAttempts = 3,
    this.delayFactor = const Duration(milliseconds: 500),
  });

  /// Number of seconds before the access token is refreshed to ensure
  /// continued access to the mediator instance.
  final int secondsBeforeExpiryReauthenticate;

  /// Specifies how often a ping is sent to the server to keep the WebSocket
  /// connection active.
  final int websocketPingInterval;

  /// Defines the maximum number of retry attempts when establishing a
  /// connection to the mediator.
  final int maxRetryAttempts;

  /// Defines the multiplier used to calculate the delay between consecutive
  /// retry attempts.
  final Duration delayFactor;
}
