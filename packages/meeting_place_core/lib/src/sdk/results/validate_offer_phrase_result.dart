/// The result of validating an offer mnemonic phrase.
class ValidateOfferPhraseResult {
  /// Creates a [ValidateOfferPhraseResult].
  ValidateOfferPhraseResult({required this.isAvailable});

  /// Whether the checked mnemonic phrase is available for use.
  final bool isAvailable;
}
