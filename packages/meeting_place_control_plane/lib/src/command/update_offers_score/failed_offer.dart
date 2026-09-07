/// Represents an offer that failed to be updated
/// (e.g. during VRC score update).
class FailedOffer {
  /// Creates a new instance of [FailedOffer].
  FailedOffer({required this.mnemonic, this.reason});

  /// Mnemonic of the offer that failed.
  final String mnemonic;

  /// Reason why the offer update failed.
  final String? reason;
}
