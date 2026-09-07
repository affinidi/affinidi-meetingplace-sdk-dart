import 'validate_offer_phrase_request.dart' show ValidateOfferPhraseRequest;

/// The result returned when an offer mnemonic is validated.
/// Model that represents the output data returned from a successful execution
/// of [ValidateOfferPhraseRequest] operation.
class ValidateOfferMnemonicResult {
  /// Creates a new instance of [ValidateOfferMnemonicResult].
  ValidateOfferMnemonicResult({required this.isAvailable});

  /// Whether the mnemonic phrase is not already in use.
  final bool isAvailable;
}
