import '../../../meeting_place_core.dart';

/// The result of [MeetingPlaceCoreSDK.acceptOffer].
class AcceptOfferResult<T extends ConnectionOffer> {
  /// Creates an [AcceptOfferResult].
  AcceptOfferResult({
    required this.connectionOffer,
    required this.acceptOfferDidManager,
    required this.permanentChannelDidManager,
  });

  /// The connection offer that was accepted.
  final T connectionOffer;

  /// The DID manager for the DID used to accept the offer.
  final DidManager acceptOfferDidManager;

  /// The DID manager for the permanent channel DID created for this
  /// connection.
  final DidManager permanentChannelDidManager;
}
