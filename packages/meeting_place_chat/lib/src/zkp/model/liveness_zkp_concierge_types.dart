/// Concierge message type values for the human liveness ZKP chat flow.
abstract final class LivenessZkpConciergeTypes {
  static const humanZkpRequest = 'humanZkpRequest';
  static const humanZkpPaused = 'humanZkpPaused';
  static const humanZkpProofShared = 'humanZkpProofShared';
  static const humanZkpProofReceived = 'humanZkpProofReceived';

  static const values = {
    humanZkpRequest,
    humanZkpPaused,
    humanZkpProofShared,
    humanZkpProofReceived,
  };

  static bool isHumanZkpType(String type) => values.contains(type);
}
