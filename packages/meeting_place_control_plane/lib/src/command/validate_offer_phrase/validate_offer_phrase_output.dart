import 'validate_offer_phrase.dart' show ValidateOfferPhraseRequest;

/// The result returned when an offer mnemonic is validated.
typedef ValidateOfferMnemonicResult = ValidateOfferPhraseCommandOutput;

/// Model that represents the output data returned from a successful execution
/// of [ValidateOfferPhraseRequest] operation.
class ValidateOfferPhraseCommandOutput {
  /// Creates a new instance of [ValidateOfferPhraseCommandOutput].
  ValidateOfferPhraseCommandOutput({required this.isAvailable});

  /// Whether the mnemonic phrase is not already in use.
  final bool isAvailable;
}
