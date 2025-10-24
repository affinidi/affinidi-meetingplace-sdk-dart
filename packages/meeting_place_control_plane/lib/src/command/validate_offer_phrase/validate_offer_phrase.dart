import '../../core/command/command.dart';
import 'validate_offer_phrase_output.dart';

/// Model that represents the request sent for the [ValidateOfferPhraseCommand]
/// operation.
class ValidateOfferPhraseCommand
    extends DiscoveryCommand<ValidateOfferPhraseCommandOutput> {
  /// Creates a new instance of [ValidateOfferPhraseCommand].
  ValidateOfferPhraseCommand({required this.phrase});
  final String phrase;
}
