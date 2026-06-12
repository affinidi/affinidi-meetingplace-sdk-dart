/// Tuneable options for `MeetingPlaceLiveKitCallPlugin`.
///
/// Pass an instance to the plugin constructor to override defaults.
/// [livekitServiceUrl] is required; all other fields have sensible defaults.
class MeetingPlaceLiveKitCallPluginOptions {
  const MeetingPlaceLiveKitCallPluginOptions({
    required this.livekitServiceUrl,
    this.livekitSfuUrl,
    this.e2eeReadyTimeout = const Duration(seconds: 10),
  });

  /// URL of the lk-jwt-service that issues LiveKit JWTs in exchange for
  /// Matrix OpenID credentials.
  ///
  /// Must be set; used by `SfuTokenService` to call `POST /sfu/get`.
  /// `MeetingPlaceLiveKitCallPlugin.isSupported` returns `false` when
  /// `livekitServiceUrl.host` is empty.
  final Uri livekitServiceUrl;

  /// WebSocket URL of the LiveKit SFU that the client connects to directly.
  ///
  /// When set, this overrides the URL returned by lk-jwt-service in the
  /// token response. Use this for local development where lk-jwt-service
  /// runs inside Docker and its `LIVEKIT_URL` is a container-internal
  /// hostname that the Flutter app cannot resolve (e.g. `ws://livekit:7880`).
  ///
  /// In production, omit this field — the SFU URL from the lk-jwt-service
  /// response is used directly.
  final Uri? livekitSfuUrl;

  /// How long to wait for E2EE keys from all remote participants before
  /// transitioning the call to the connected status without confirmed
  /// encryption.
  ///
  /// On slow or high-latency networks you may want to increase this value
  /// to avoid the fallback transition triggering prematurely. On controlled
  /// networks a shorter value improves perceived responsiveness.
  ///
  /// Defaults to 10 seconds.
  final Duration e2eeReadyTimeout;
}
