import '../../core/command/command.dart';
import 'validate_offer_mnemonic_result.dart';

/// Model that represents the request sent for the [ValidateOfferPhraseRequest]
/// operation.
class ValidateOfferPhraseRequest
    extends DiscoveryCommand<ValidateOfferMnemonicResult> {
  /// Creates a new instance of [ValidateOfferPhraseRequest].
  ValidateOfferPhraseRequest({required this.mnemonic});

  /// The mnemonic phrase to validate for availability.
  final String mnemonic;
}
