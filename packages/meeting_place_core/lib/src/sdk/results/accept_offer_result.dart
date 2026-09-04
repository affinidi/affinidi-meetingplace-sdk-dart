import '../../../meeting_place_core.dart';

enum AcceptOfferResultErrorCode {
  offerOwnedByClaimingParty('OFFER_OWNED_BY_CLAIMING_PARTY'),
  offerAlreadyClaimedByParty('OFFER_ALREADY_CLAIMED_BY_PARTY');

  const AcceptOfferResultErrorCode(this.value);

  final String value;
}

class OfferMaximumClaimLimitExceeded implements Exception {}

class AcceptOfferResult<T extends ConnectionOffer> {
  AcceptOfferResult({
    required this.connectionOffer,
    required this.acceptOfferDidManager,
    required this.permanentChannelDidManager,
  });
  final T connectionOffer;
  final DidManager acceptOfferDidManager;
  final DidManager permanentChannelDidManager;
}
