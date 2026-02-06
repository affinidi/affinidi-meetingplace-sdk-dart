import 'failed_offer.dart';

/// Output model for [UpdateOffersScoreCommand].
class UpdateOffersScoreCommandOutput {
  UpdateOffersScoreCommandOutput({
    required this.updatedOffers,
    required this.failedOffers,
  });

  /// Mnemonics that were successfully updated.
  final List<String> updatedOffers;

  /// Offers that failed to update, with optional reason.
  final List<FailedOffer> failedOffers;
}
