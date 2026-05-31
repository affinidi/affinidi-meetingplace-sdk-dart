/// Provider-neutral result of a liveness check.
///
/// Any liveness vendor (AWS Rekognition, Azure Face API, Onfido, etc.) should
/// map its response into this model before issuing a [LivenessCredential].
class LivenessEvidence {
  const LivenessEvidence({
    required this.providerId,
    required this.providerTransactionId,
    required this.livenessScore,
    required this.livenessThreshold,
    required this.checkedAt,
  });

  /// Stable identifier for the liveness vendor, e.g. `aws_rekognition`.
  final String providerId;

  /// Provider-specific session or transaction reference.
  final String providerTransactionId;

  final double livenessScore;
  final double livenessThreshold;
  final DateTime checkedAt;

  bool get isLive => livenessScore >= livenessThreshold;
}
