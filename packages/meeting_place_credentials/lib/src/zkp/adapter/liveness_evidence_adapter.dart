import '../model/liveness_evidence.dart';

/// Converts provider-specific liveness responses into [LivenessEvidence].
///
/// Implement in provider packages (AWS Rekognition, Azure Face API, etc.) to
/// keep credential issuance decoupled from vendor payload shapes.
abstract interface class LivenessEvidenceAdapter<T> {
  LivenessEvidence toLivenessEvidence(T providerResponse);
}
