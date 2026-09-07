/// Concierge message type values for the human liveness ZKP chat flow.
abstract final class LivenessZkpConciergeTypes {
  /// The other party has requested a human liveness ZKP proof.
  static const humanZkpRequest = 'humanZkpRequest';

  /// The current user has sent a human liveness ZKP request.
  static const humanZkpRequestInitiated = 'humanZkpRequestInitiated';

  /// The human liveness ZKP flow is paused.
  static const humanZkpPaused = 'humanZkpPaused';

  /// A human liveness ZKP request was declined.
  static const humanZkpDeclined = 'humanZkpDeclined';

  /// The current user has shared a human liveness ZKP proof.
  static const humanZkpProofShared = 'humanZkpProofShared';

  /// The other party has shared a human liveness ZKP proof.
  static const humanZkpProofReceived = 'humanZkpProofReceived';

  /// All known human liveness ZKP concierge type values.
  static const values = {
    humanZkpRequest,
    humanZkpRequestInitiated,
    humanZkpPaused,
    humanZkpDeclined,
    humanZkpProofShared,
    humanZkpProofReceived,
  };

  /// Whether [type] is one of the human liveness ZKP concierge [values].
  static bool isHumanZkpType(String type) => values.contains(type);
}
