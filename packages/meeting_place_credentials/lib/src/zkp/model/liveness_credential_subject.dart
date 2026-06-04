import 'liveness_evidence.dart';

/// Credential subject payload for a signed liveness VC.
class LivenessCredentialSubject {
  /// Creates a liveness credential subject for the given holder.
  const LivenessCredentialSubject({
    required this.holderDid,
    required this.evidence,
  });

  /// DID of the person that completed the liveness check.
  final String holderDid;

  /// Normalized evidence that will be embedded in the credential subject.
  final LivenessEvidence evidence;

  /// Serializes the subject into the JSON-LD credential subject shape.
  Map<String, Object?> toJson() => {
    'id': holderDid,
    'livenessProvider': evidence.providerId,
    'livenessSessionId': evidence.providerTransactionId,
    'livenessScore': evidence.livenessScore,
    'livenessThreshold': evidence.livenessThreshold,
    'livenessPassed': evidence.isLive,
    'checkedAt': evidence.checkedAt.toUtc().toIso8601String(),
  };
}
