import 'liveness_zkp_constants.dart';

/// Parsed liveness check request attachment payload.
final class LivenessCheckRequestPayload {
  /// Parses and validates a decoded JSON map from a liveness-request.
  ///
  /// Throws [FormatException] if [LivenessZkpConstants.typeJsonKey] is missing
  factory LivenessCheckRequestPayload.fromJson(Map<String, dynamic> json) {
    final type = json[LivenessZkpConstants.typeJsonKey];
    if (type != LivenessZkpConstants.livenessRequestPayloadType) {
      throw const FormatException(
        'Missing or invalid "${LivenessZkpConstants.typeJsonKey}"',
      );
    }
    return const LivenessCheckRequestPayload();
  }

  const LivenessCheckRequestPayload();

  Map<String, dynamic> toJson() => {
    LivenessZkpConstants.typeJsonKey:
        LivenessZkpConstants.livenessRequestPayloadType,
  };
}
