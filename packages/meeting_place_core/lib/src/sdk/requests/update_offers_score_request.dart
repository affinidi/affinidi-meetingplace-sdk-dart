import '../../entity/connection_offer.dart';

/// Parameters for `MeetingPlaceCoreSDK.updateOffersScore` and
/// `MeetingPlaceCoreSDK.updateOffersScoreLocally`.
class UpdateOffersScoreRequest {
  const UpdateOffersScoreRequest({required this.score, required this.offers});

  /// The new trust score (VRC count) to associate with [offers].
  final int score;

  /// The connection offers to update.
  final List<ConnectionOffer> offers;
}
