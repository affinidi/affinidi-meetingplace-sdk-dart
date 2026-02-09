/// Represents an offer that failed to be updated (e.g. during VRC score
/// update).
class FailedOffer {
  FailedOffer({required this.mnemonic, this.reason});

  /// Mnemonic of the offer that failed.
  final String mnemonic;

  /// Optional reason for the failure.
  final String? reason;
}
