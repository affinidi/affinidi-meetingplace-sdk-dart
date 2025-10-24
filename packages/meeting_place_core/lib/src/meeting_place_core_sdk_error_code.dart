enum MeetingPlaceCoreSDKErrorCode {
  // group membership finalised codes
  groupMembershipFinalisedConnectionOfferGroupNotFound(
      'group_membership_finalised_connection_offer_group_not_found'),
  groupMembershipFinalisedConnectionOfferAlreadyFinalizedException(
      'group_membership_finalised_connection_offer_already_finalized'),
  groupMembershipFinalisedGroupConnectionOfferRequired(
      'group_membership_finalised_group_connection_offer_required'),
  groupMembershipFinalisedChannelNotFound(
      'group_membership_finalised_channel_not_found'),

  // connection offer codes
  connectionOfferOwnedByClaimingParty(
      'connection_offer_owned_by_claiming_party'),
  connectionOfferAlreadyClaimedByClaimingParty(
      'connection_offer_already_claimed_by_claiming_party'),
  connectionOfferPublishError('connection_offer_publish_error'),
  connectionOfferNotFoundError('connection_offer_not_found_error'),
  connectionOfferPermanentChannelDidError(
      'connection_offer_permanent_channel_did_error'),
  connectionOfferNotAcceptedError('connection_offer_not_accepted_error'),
  connectionOfferAlreadyFinalised('connection_offer_already_finalised'),

  // connection manager codes
  keyPairNotFoundError('key_pair_not_found'),

  // group codes
  groupNotFoundError('group_not_found_error'),
  groupMemberDidIsNull('group_member_did_is_null'),
  groupMemberDoesNotBelongToGroupError(
    'group_member_does_not_belong_to_group_error',
  ),
  groupOfferDoesNotExistError('group_offer_does_not_exist_error'),
  groupChannelDoesNotExistError('group_offer_channel_does_not_exist_error'),

  // others
  generic('generic');

  const MeetingPlaceCoreSDKErrorCode(this.value);
  final String value;
}
