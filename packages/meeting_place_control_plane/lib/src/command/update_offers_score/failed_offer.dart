/// Represents an offer that failed to be updated (e.g. during VRC score update).
class FailedOffer {
  FailedOffer({
    this.mnemonic,
    this.offerLink,
    this.reason,
  }) : assert(
         mnemonic != null || offerLink != null,
         'At least one of mnemonic or offerLink must be set',
       );

  /// Mnemonic of the offer that failed, if available.
  final String? mnemonic;

  /// Offer link of the offer that failed, if available.
  final String? offerLink;

  /// Optional reason or error code for the failure.
  final String? reason;
}
