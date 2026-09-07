import '../../core/command/command.dart';
import 'validate_offer_phrase_output.dart';

/// Model that represents the request sent for the [ValidateOfferPhraseRequest]
/// operation.
class ValidateOfferPhraseRequest
    extends DiscoveryCommand<ValidateOfferPhraseCommandOutput> {
  /// Creates a new instance of [ValidateOfferPhraseRequest].
  ValidateOfferPhraseRequest({required this.mnemonic});

  /// The mnemonic phrase to validate for availability.
  final String mnemonic;
}
