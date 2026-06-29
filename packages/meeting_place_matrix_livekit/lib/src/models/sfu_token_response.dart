/// Response from the lk-jwt-service `/sfu/get` endpoint.
class SfuTokenResponse {
  const SfuTokenResponse({required this.token, this.url});

  /// LiveKit JWT for connecting to the SFU.
  final String token;

  /// WebSocket URL of the LiveKit SFU (e.g. `wss://livekit.example.com`).
  ///
  /// May be absent when the client has a pre-configured SFU URL.
  final String? url;
}
