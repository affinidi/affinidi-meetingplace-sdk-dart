import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    show FailedOffer;

/// Result of [MeetingPlaceCoreSDK.updateVrcScoreForOffers].
///
/// Exposes [updatedOffers] and [failedOffers] so the client can handle
/// success and failure per offer.
class UpdateScoreForOffersResult {
  UpdateScoreForOffersResult({
    required this.updatedOffers,
    required this.failedOffers,
  });

  /// Mnemonics that were successfully updated.
  final List<String> updatedOffers;

  /// Offers that failed to update.
  final List<FailedOffer> failedOffers;
}
