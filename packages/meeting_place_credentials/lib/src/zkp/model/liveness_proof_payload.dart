import 'liveness_zkp_protocol.dart';

/// Parsed liveness proof attachment payload (`proof` + `publicSignals`).
final class LivenessProofPayload {
  /// Parses and validates a decoded JSON map from a liveness-proof attachment.
  ///
  /// Throws [FormatException] if required fields are missing or invalid.
  factory LivenessProofPayload.fromJson(Map<String, dynamic> json) {
    final type = json[LivenessZkpProtocol.typeJsonKey];
    if (type != LivenessZkpProtocol.livenessProofPayloadType) {
      throw const FormatException(
        'Missing or invalid "${LivenessZkpProtocol.typeJsonKey}"',
      );
    }

    final proof = json[LivenessZkpProtocol.proofJsonKey];
    final publicSignals = json[LivenessZkpProtocol.publicSignalsJsonKey];

    if (proof is! String || proof.isEmpty) {
      throw const FormatException(
        'Missing or invalid "${LivenessZkpProtocol.proofJsonKey}"',
      );
    }
    if (publicSignals is! String || publicSignals.isEmpty) {
      throw const FormatException(
        'Missing or invalid "${LivenessZkpProtocol.publicSignalsJsonKey}"',
      );
    }

    return LivenessProofPayload(proof: proof, publicSignals: publicSignals);
  }

  /// Creates a liveness proof payload for [proof] and [publicSignals].
  const LivenessProofPayload({
    required this.proof,
    required this.publicSignals,
  });

  /// The serialized zero-knowledge liveness proof.
  final String proof;

  /// The serialized public signals accompanying [proof].
  final String publicSignals;

  /// Serializes the payload into the DIDComm attachment JSON shape.
  Map<String, dynamic> toJson() => {
    LivenessZkpProtocol.typeJsonKey:
        LivenessZkpProtocol.livenessProofPayloadType,
    LivenessZkpProtocol.proofJsonKey: proof,
    LivenessZkpProtocol.publicSignalsJsonKey: publicSignals,
  };
}
