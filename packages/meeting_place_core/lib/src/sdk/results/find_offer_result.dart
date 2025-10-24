import '../../../meeting_place_core.dart';

enum FindOfferResultErrorCode {
  offerOwnedByClaimingParty('OFFER_OWNED_BY_CLAIMING_PARTY'),
  offerAlreadyClaimedByParty('OFFER_ALREADY_CLAIMED_BY_PARTY');

  const FindOfferResultErrorCode(this.value);

  final String value;
}

class OfferNotFoundException implements Exception {}

class FindOfferResult {
  FindOfferResult({required this.connectionOffer, this.errorCode});
  final ConnectionOffer? connectionOffer;
  final FindOfferResultErrorCode? errorCode;
}
