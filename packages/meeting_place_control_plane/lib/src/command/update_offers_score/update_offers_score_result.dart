import 'failed_offer.dart';
import 'update_offers_score_request.dart' show UpdateOffersScoreRequest;

/// The result returned when offer scores are updated.
/// Output model for [UpdateOffersScoreRequest].
class UpdateOffersScoreResult {
  /// Creates a new instance of [UpdateOffersScoreResult].
  UpdateOffersScoreResult({
    required this.updatedOffers,
    required this.failedOffers,
  });

  /// Mnemonics that were successfully updated.
  final List<String> updatedOffers;

  /// Offers that failed to update, with optional reason.
  final List<FailedOffer> failedOffers;
}
