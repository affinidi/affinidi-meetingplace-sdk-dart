import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    show FailedOffer;

/// Result of `MeetingPlaceCoreSDK.updateOffersScore`.
class UpdateOffersScoreResult {
  UpdateOffersScoreResult({
    required this.updatedOffers,
    required this.failedOffers,
  });

  /// Mnemonics that were successfully updated.
  final List<String> updatedOffers;

  /// Offers that failed to update.
  final List<FailedOffer> failedOffers;
}
