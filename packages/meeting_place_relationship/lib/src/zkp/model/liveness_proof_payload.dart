import 'liveness_zkp_constants.dart';

/// Parsed liveness proof attachment payload (`proof` + `publicSignals`).
final class LivenessProofPayload {
  /// Parses and validates a decoded JSON map from a liveness-proof attachment.
  ///
  /// Throws [FormatException] if required fields are missing or wrong type.
  /// [LivenessZkpConstants.livenessProofPayloadType].
  factory LivenessProofPayload.fromJson(Map<String, dynamic> json) {
    final type = json[LivenessZkpConstants.typeJsonKey];
    if (type != null && type != LivenessZkpConstants.livenessProofPayloadType) {
      throw FormatException('Unexpected liveness ZKP payload type: $type');
    }

    final proof = json[LivenessZkpConstants.proofJsonKey];
    final publicSignals = json[LivenessZkpConstants.publicSignalsJsonKey];

    if (proof is! String || proof.isEmpty) {
      throw const FormatException(
        'Missing or invalid "${LivenessZkpConstants.proofJsonKey}"',
      );
    }
    if (publicSignals is! String || publicSignals.isEmpty) {
      throw const FormatException(
        'Missing or invalid "${LivenessZkpConstants.publicSignalsJsonKey}"',
      );
    }

    return LivenessProofPayload(proof: proof, publicSignals: publicSignals);
  }
  const LivenessProofPayload({
    required this.proof,
    required this.publicSignals,
  });

  final String proof;
  final String publicSignals;

  Map<String, dynamic> toJson() => {
    LivenessZkpConstants.typeJsonKey:
        LivenessZkpConstants.livenessProofPayloadType,
    LivenessZkpConstants.proofJsonKey: proof,
    LivenessZkpConstants.publicSignalsJsonKey: publicSignals,
  };
}
