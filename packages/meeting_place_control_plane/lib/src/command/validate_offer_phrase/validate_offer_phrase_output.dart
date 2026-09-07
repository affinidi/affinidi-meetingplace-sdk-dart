import 'validate_offer_phrase.dart' show ValidateOfferPhraseCommand;

/// Model that represents the output data returned from a successful execution
/// of [ValidateOfferPhraseCommand] operation.
class ValidateOfferPhraseCommandOutput {
  /// Creates a new instance of [ValidateOfferPhraseCommandOutput].
  ValidateOfferPhraseCommandOutput({required this.isAvailable});

  /// Whether the mnemonic phrase is not already in use.
  final bool isAvailable;
}
