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
    required this.acceptOfferDid,
    required this.permanentChannelDid,
  });
  final T connectionOffer;
  final DidManager acceptOfferDid;
  final DidManager permanentChannelDid;
}
