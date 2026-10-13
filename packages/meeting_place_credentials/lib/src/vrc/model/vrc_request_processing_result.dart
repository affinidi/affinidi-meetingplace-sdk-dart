/// Result of processing a received VRC issuance request in the
/// credentials SDK.
sealed class VrcRequestProcessingResult {
  /// Base constructor for [VrcRequestProcessingResult] subclasses.
  const VrcRequestProcessingResult();
}

/// The consumer should prompt the user to initiate a VRC exchange.
final class VrcRequestProcessingResultPromptRequired
    extends VrcRequestProcessingResult {
  /// Creates a prompt result. The exchange has not started; surface the
  /// initiation action to the user.
  const VrcRequestProcessingResultPromptRequired();
}

/// The local party is waiting for the peer to send a VRC first.
final class VrcRequestProcessingResultWaiting
    extends VrcRequestProcessingResult {
  /// Creates a waiting result. Both parties sent a request simultaneously
  /// but this party is not the initiator; wait for the peer's VRC to arrive.
  const VrcRequestProcessingResultWaiting();
}

/// The peer-supplied identity DID in the request could not be resolved.
///
/// Only returned on the simultaneous-request auto-issue path, where this
/// party would otherwise sign the peer DID into an issued VC. The DID was
/// shaped correctly but does not resolve to a real DID document, so no VC
/// is issued against it.
final class VrcRequestProcessingResultUnresolvableIdentity
    extends VrcRequestProcessingResult {
  /// Creates an unresolvable-identity result for [peerDid].
  const VrcRequestProcessingResultUnresolvableIdentity(this.peerDid);

  /// The peer-supplied identity DID that failed resolution.
  final String peerDid;
}

/// A VRC was auto-issued to the peer (simultaneous-request initiator path).
///
/// [sentVcBlob] is the raw VC JSON of the issued VRC.
final class VrcRequestProcessingResultIssued
    extends VrcRequestProcessingResult {
  /// Creates an issued result. Both parties sent a request simultaneously
  /// and this party is the initiator, so a VRC was auto-issued.
  /// [sentVcBlob] is the raw VC JSON of the issued VRC; show it as an
  /// outgoing card.
  const VrcRequestProcessingResultIssued(this.sentVcBlob);

  /// The raw VC JSON of the VRC auto-issued to the peer.
  final String sentVcBlob;
}
