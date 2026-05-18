import 'liveness_zkp_protocol.dart';

/// Parsed liveness check request attachment payload.
final class LivenessCheckRequestPayload {
  /// Parses and validates a decoded JSON map from a liveness-request.
  ///
  /// Throws [FormatException] if [LivenessZkpProtocol.typeJsonKey] is missing
  factory LivenessCheckRequestPayload.fromJson(Map<String, dynamic> json) {
    final type = json[LivenessZkpProtocol.typeJsonKey];
    if (type != LivenessZkpProtocol.livenessRequestPayloadType) {
      throw const FormatException(
        'Missing or invalid "${LivenessZkpProtocol.typeJsonKey}"',
      );
    }
    return const LivenessCheckRequestPayload();
  }

  const LivenessCheckRequestPayload();

  Map<String, dynamic> toJson() => {
    LivenessZkpProtocol.typeJsonKey:
        LivenessZkpProtocol.livenessRequestPayloadType,
  };
}
