import 'package:freezed_annotation/freezed_annotation.dart';

part 'sfu_token_response.freezed.dart';

/// Response from the lk-jwt-service `/sfu/get` endpoint.
@Freezed(fromJson: false, toJson: false)
abstract class SfuTokenResponse with _$SfuTokenResponse {
  const factory SfuTokenResponse({
    /// LiveKit JWT for connecting to the SFU.
    required String token,

    /// WebSocket URL of the LiveKit SFU (e.g. `wss://livekit.example.com`).
    ///
    /// May be absent when the client has a pre-configured SFU URL.
    String? url,
  }) = _SfuTokenResponse;
}
