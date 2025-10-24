import 'package:ssi/ssi.dart';

class MeetingPlaceMediatorSDKOptions {
  const MeetingPlaceMediatorSDKOptions({
    this.secondsBeforeExpiryReauthenticate = 60,
    this.websocketPingInterval = 30,
    this.maxRetries = 3,
    this.maxRetriesDelay = const Duration(milliseconds: 2000),
    this.signatureScheme = SignatureScheme.ecdsa_p256_sha256,
  });

  /// Number of seconds before the access token is refreshed to ensure
  /// continued access to the mediator instance.
  final int secondsBeforeExpiryReauthenticate;

  /// Specifies how often a ping is sent to the server to keep the WebSocket
  /// connection active.
  final int websocketPingInterval;

  /// Defines the maximum number of retry attempts when establishing a
  /// connection to the mediator.
  final int maxRetries;

  /// The maximum delay between retry attempts when a network issue occurs.
  /// This value sets the upper bound for the delay between retries.
  final Duration maxRetriesDelay;

  // Signature scheme to use for signing messages sent to the mediator.
  final SignatureScheme signatureScheme;
}
