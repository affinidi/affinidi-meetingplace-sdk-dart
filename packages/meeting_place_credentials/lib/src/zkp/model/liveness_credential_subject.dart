import 'liveness_evidence.dart';

class LivenessCredentialSubject {
  const LivenessCredentialSubject({
    required this.holderDid,
    required this.evidence,
  });

  final String holderDid;
  final LivenessEvidence evidence;

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
