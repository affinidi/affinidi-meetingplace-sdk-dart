import '../model/liveness_evidence.dart';

/// Collects [LivenessEvidence] from a configured liveness provider.
///
/// Implement this in the app or in a provider-specific package.
abstract interface class LivenessEvidenceSource {
  Future<LivenessEvidence> getEvidence({required String holderDid});
}
