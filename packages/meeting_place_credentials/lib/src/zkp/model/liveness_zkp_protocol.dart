/// DIDComm attachment formats and JSON field names for liveness credential
/// transport.
abstract final class LivenessZkpProtocol {
  /// DIDComm attachment format for liveness check requests.
  static const livenessCheckRequestFormat =
      'https://affinidi.com/liveness-check-request';

  /// DIDComm attachment format for liveness proofs.
  static const livenessProofFormat = 'https://affinidi.com/liveness-proof';

  /// JSON `type` value for liveness check request payloads.
  static const livenessRequestPayloadType = 'liveness_request';

  /// JSON `type` value for liveness proof payloads.
  static const livenessProofPayloadType = 'liveness_proof';

  /// JSON field name for payload type discriminators.
  static const typeJsonKey = 'type';

  /// JSON field name for the proof blob.
  static const proofJsonKey = 'proof';

  /// JSON field name for the proof public signals.
  static const publicSignalsJsonKey = 'publicSignals';

  /// 32-byte verifier challenge as 64 lowercase hex characters.
  static const challengeNonceJsonKey = 'challengeNonce';
}
