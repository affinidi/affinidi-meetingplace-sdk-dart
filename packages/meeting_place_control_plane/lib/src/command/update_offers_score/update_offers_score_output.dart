import 'failed_offer.dart';
import 'update_offers_score.dart' show UpdateOffersScoreCommand;

/// Output model for [UpdateOffersScoreCommand].
class UpdateOffersScoreCommandOutput {
  /// Creates a new instance of [UpdateOffersScoreCommandOutput].
  UpdateOffersScoreCommandOutput({
    required this.updatedOffers,
    required this.failedOffers,
  });

  /// Mnemonics that were successfully updated.
  final List<String> updatedOffers;

  /// Offers that failed to update, with optional reason.
  final List<FailedOffer> failedOffers;
}
