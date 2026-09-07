import 'liveness_zkp_protocol.dart';

const _challengeNonceByteLength = 32;
final _challengeNonceHexPattern = RegExp(r'^[0-9a-f]{64}$');

/// Parsed liveness check request attachment payload.
final class LivenessCheckRequestPayload {
  /// Parses and validates a decoded JSON map from a liveness-request.
  ///
  /// Throws [FormatException] if [LivenessZkpProtocol.typeJsonKey] is missing
  /// or invalid, or if [LivenessZkpProtocol.challengeNonceJsonKey] is missing
  /// or not a valid 64-character hex string.
  factory LivenessCheckRequestPayload.fromJson(Map<String, dynamic> json) {
    final type = json[LivenessZkpProtocol.typeJsonKey];
    if (type != LivenessZkpProtocol.livenessRequestPayloadType) {
      throw const FormatException(
        'Missing or invalid "${LivenessZkpProtocol.typeJsonKey}"',
      );
    }

    final challengeNonceHex =
        json[LivenessZkpProtocol.challengeNonceJsonKey]?.toString() ?? '';
    if (!_challengeNonceHexPattern.hasMatch(challengeNonceHex)) {
      throw const FormatException(
        'Missing or invalid "${LivenessZkpProtocol.challengeNonceJsonKey}"',
      );
    }

    return LivenessCheckRequestPayload(challengeNonceHex: challengeNonceHex);
  }

  /// Creates a liveness check request payload for [challengeNonceHex].
  const LivenessCheckRequestPayload({required this.challengeNonceHex});

  /// The 64-character hex-encoded challenge nonce the peer must include in
  /// its liveness proof.
  final String challengeNonceHex;

  /// The raw bytes decoded from [challengeNonceHex].
  List<int> get challengeNonceBytes =>
      List<int>.generate(_challengeNonceByteLength, (index) {
        final start = index * 2;
        return int.parse(
          challengeNonceHex.substring(start, start + 2),
          radix: 16,
        );
      });

  /// Serializes the payload into the DIDComm attachment JSON shape.
  Map<String, dynamic> toJson() => {
    LivenessZkpProtocol.typeJsonKey:
        LivenessZkpProtocol.livenessRequestPayloadType,
    LivenessZkpProtocol.challengeNonceJsonKey: challengeNonceHex,
  };
}
