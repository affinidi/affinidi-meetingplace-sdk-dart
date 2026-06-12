/// Provider-neutral result of a liveness check.
///
/// Any liveness vendor (AWS Rekognition, Azure Face API, Onfido, etc.) should
/// map its response into this model before issuing a liveness VC.
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

  /// Provider specific session
  final String providerTransactionId;

  /// Vendor reported liveness confidence score for the session.
  final double livenessScore;

  /// Minimum [livenessScore] required to treat the check as passed.
  final double livenessThreshold;

  /// When the liveness check was completed (UTC).
  final DateTime checkedAt;

  /// Whether [livenessScore] meets or exceeds [livenessThreshold].
  bool get isLive => livenessScore >= livenessThreshold;
}
