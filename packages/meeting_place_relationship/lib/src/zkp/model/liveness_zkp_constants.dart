abstract final class LivenessZkpConstants {
  static const livenessCheckRequestFormat =
      'https://affinidi.com/liveness-check-request';

  static const livenessProofFormat = 'https://affinidi.com/liveness-proof';

  static const livenessRequestPayloadType = 'liveness_request';

  static const livenessProofPayloadType = 'liveness_proof';

  static const typeJsonKey = 'type';

  static const proofJsonKey = 'proof';

  static const publicSignalsJsonKey = 'publicSignals';

  static const conciergeHumanZkpRequest = 'humanZkpRequest';

  static const conciergeHumanZkpPaused = 'humanZkpPaused';

  static const conciergeHumanZkpProofShared = 'humanZkpProofShared';

  static const conciergeHumanZkpProofReceived = 'humanZkpProofReceived';

  static const vcExpiryDuration = Duration(days: 5);

  static const vcIssuerName = 'Affinidi';

  static const livenessSchemaVersion = 'liveness-v1';
}
