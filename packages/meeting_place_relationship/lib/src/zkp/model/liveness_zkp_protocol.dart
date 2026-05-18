/// DIDComm attachment formats and JSON fields for the liveness ZKP protocol.
abstract final class LivenessZkpProtocol {
  static const livenessCheckRequestFormat =
      'https://affinidi.com/liveness-check-request';

  static const livenessProofFormat = 'https://affinidi.com/liveness-proof';

  static const livenessRequestPayloadType = 'liveness_request';

  static const livenessProofPayloadType = 'liveness_proof';

  static const typeJsonKey = 'type';

  static const proofJsonKey = 'proof';

  static const publicSignalsJsonKey = 'publicSignals';
}
