/// Result of processing a received VRC in the credentials SDK.
sealed class VrcProcessingResult {
  const VrcProcessingResult();
}

/// The incoming VRC was ignored — either the exchange state does not require
/// a response, or the exchange was already completed.
final class VrcProcessingResultIgnored extends VrcProcessingResult {
  /// Creates an ignored result. The exchange state did not require any
  /// action, or duplicate delivery was detected.
  const VrcProcessingResultIgnored();
}

/// The incoming VRC completed the exchange. No VRC was sent back.
final class VrcProcessingResultCompleted extends VrcProcessingResult {
  /// Creates a completed result. The peer's VRC finished the exchange;
  /// no reciprocating VRC was sent.
  const VrcProcessingResultCompleted();
}

/// The incoming VRC triggered reciprocation. [sentVcBlob] is the raw VC JSON
/// of the VRC that was sent back to the peer.
final class VrcProcessingResultReciprocated extends VrcProcessingResult {
  /// Creates a reciprocated result. [sentVcBlob] is the raw VC JSON of the
  /// VRC auto-issued back to the peer; show it as an outgoing card after
  /// showing the incoming card.
  const VrcProcessingResultReciprocated(this.sentVcBlob);

  /// The raw VC JSON of the VRC issued back to the peer.
  final String sentVcBlob;
}
