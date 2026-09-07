import 'liveness_zkp_protocol.dart';

/// Parsed liveness declined attachment payload.
final class LivenessDeclinedPayload {
  /// Parses and validates a decoded JSON map from a liveness-declined message.
  ///
  /// Throws [FormatException] if required fields are missing or invalid.
  factory LivenessDeclinedPayload.fromJson(Map<String, dynamic> json) {
    final type = json[LivenessZkpProtocol.typeJsonKey];
    if (type != LivenessZkpProtocol.livenessDeclinedPayloadType) {
      throw const FormatException(
        'Missing or invalid "${LivenessZkpProtocol.typeJsonKey}"',
      );
    }

    return const LivenessDeclinedPayload();
  }

  /// Creates a liveness declined payload.
  const LivenessDeclinedPayload();

  /// Serializes the payload into the DIDComm attachment JSON shape.
  Map<String, dynamic> toJson() => {
    LivenessZkpProtocol.typeJsonKey:
        LivenessZkpProtocol.livenessDeclinedPayloadType,
  };
}
