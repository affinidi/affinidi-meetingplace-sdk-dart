import '../../../meeting_place_core.dart';

/// Error codes returned in [FindOfferResult.errorCode] when a matched offer
/// can't be claimed by the caller.
enum FindOfferResultErrorCode {
  /// The offer was published by the party now trying to claim it.
  offerOwnedByClaimingParty('OFFER_OWNED_BY_CLAIMING_PARTY'),

  /// The offer has already been claimed by the party trying to claim it.
  offerAlreadyClaimedByParty('OFFER_ALREADY_CLAIMED_BY_PARTY');

  const FindOfferResultErrorCode(this.value);

  /// The wire value of this error code.
  final String value;
}

/// The result of [MeetingPlaceCoreSDK.findOffer].
class FindOfferResult {
  /// Creates a [FindOfferResult].
  FindOfferResult({required this.connectionOffer, this.errorCode});

  /// The matched connection offer, or `null` if no offer was found.
  final ConnectionOffer? connectionOffer;

  /// The reason [connectionOffer] can't be claimed by the caller, or `null`
  /// if it can be.
  final FindOfferResultErrorCode? errorCode;
}
