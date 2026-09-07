/// Error codes carried by `MeetingPlaceCoreSDKException` to identify the
/// specific failure that occurred within a `MeetingPlaceCoreSDK` call.
enum MeetingPlaceCoreSDKErrorCode {
  // group membership finalised codes
  /// A group membership finalised event referenced a connection offer that
  /// is already finalized.
  groupMembershipFinalisedConnectionOfferGroupNotFound(
    'group_membership_finalised_connection_offer_group_not_found',
  ),

  /// Unused: reserved for a group membership finalised event referencing a
  /// connection offer that has already been finalized.
  groupMembershipFinalisedConnectionOfferAlreadyFinalizedException(
    'group_membership_finalised_connection_offer_already_finalized',
  ),

  /// A group membership finalised event referenced a connection offer that
  /// is not of type group.
  groupMembershipFinalisedGroupConnectionOfferRequired(
    'group_membership_finalised_group_connection_offer_required',
  ),

  /// A group membership finalised event referenced a channel that could not
  /// be found.
  groupMembershipFinalisedChannelNotFound(
    'group_membership_finalised_channel_not_found',
  ),

  // inivitation accepted group codes
  /// An invitation accepted message for a group did not include the
  /// expected contact card.
  invitationAcceptedGroupContactCardNotPresent(
    'invitation_accepted_group_contact_card_not_present',
  ),

  // connection offer codes
  /// A party tried to claim a connection offer that they themselves
  /// published.
  connectionOfferOwnedByClaimingParty(
    'connection_offer_owned_by_claiming_party',
  ),

  /// A party tried to claim a connection offer they had already claimed.
  connectionOfferAlreadyClaimedByClaimingParty(
    'connection_offer_already_claimed_by_claiming_party',
  ),

  /// Publishing a connection offer failed.
  connectionOfferPublishError('connection_offer_publish_error'),

  /// No connection offer matched the given lookup criteria.
  connectionOfferNotFoundError('connection_offer_not_found_error'),

  /// A connection offer was expected to have a permanent channel DID but
  /// did not.
  connectionOfferPermanentChannelDidError(
    'connection_offer_permanent_channel_did_error',
  ),

  /// An operation required the connection offer to have been accepted, but
  /// it had not.
  connectionOfferNotAcceptedError('connection_offer_not_accepted_error'),

  /// The connection offer has already been finalised.
  connectionOfferAlreadyFinalised('connection_offer_already_finalised'),

  /// The connection offer is not of the type expected by the operation.
  connectionOfferInvalidType('connection_offer_invalid_type'),

  /// The connection offer has reached its maximum allowed usage count.
  connectionOfferLimitExceeded('connection_offer_limit_exceeded'),

  /// The connection offer has expired.
  connectionOfferExpired('connection_offer_expired'),

  // connection manager codes
  /// No key pair was found for the requested DID.
  keyPairNotFoundError('key_pair_not_found'),

  // group codes
  /// No group matched the given lookup criteria.
  groupNotFoundError('group_not_found_error'),

  /// A group member's DID was null when one was required.
  groupMemberDidIsNull('group_member_did_is_null'),

  /// The specified member does not belong to the group.
  groupMemberDoesNotBelongToGroupError(
    'group_member_does_not_belong_to_group_error',
  ),

  /// The connection offer for the group does not exist.
  groupOfferDoesNotExistError('group_offer_does_not_exist_error'),

  /// The channel for the group does not exist.
  groupChannelDoesNotExistError('group_offer_channel_does_not_exist_error'),

  /// The caller attempted an owner-only group operation without being the
  /// group's owner.
  groupCallerIsNotOwnerError('group_caller_is_not_owner_error'),

  /// The caller attempted to remove the group owner, which is not allowed.
  groupCannotRemoveOwnerError('group_cannot_remove_owner_error'),

  // channels
  /// The requested action is not allowed on the channel in its current
  /// state.
  channelActionNotAllowed('channel_action_not_allowed'),

  /// Notifying a channel peer or group about activity failed.
  channelNotificationFailed('channel_notification_failed'),

  /// No channel matched the given lookup criteria.
  channelNotFound('channel_not_found'),

  /// The channel's status is not one of the statuses expected by the
  /// operation.
  channelInvalidStatus('channel_invalid_status'),

  /// The channel's type is not one of the types expected by the operation.
  channelInvalidType('channel_invalid_type'),

  /// The channel is missing its permanent channel DID, which the operation
  /// requires.
  channelMissingPermanentChannelDid('channel_missing_permanent_channel_did'),

  // direct connection
  /// The direct connection invitation data returned by the server is
  /// invalid.
  directConnectionInvalidData('direct_connection_invalid_data'),

  /// The direct connection invitation is malformed: a required field (id,
  /// from, body) is missing or has the wrong type.
  directConnectionMalformedInvitation('direct_connection_malformed_invitation'),

  /// No direct connection invitation was found for the given URL.
  directConnectionNotFound('direct_connection_not_found'),

  /// The direct connection invitation's type did not match the type
  /// expected by the operation.
  directConnectionInvalidType('direct_connection_invalid_type'),

  // others
  /// The mediator access-control list is missing expected channel DIDs.
  mediatorAclMissingChannelDids('mediator_acl_missing_channel_dids'),

  /// A network error occurred while communicating with a remote service.
  networkError('network_error'),

  /// An unclassified error occurred; no more specific code applies.
  generic('generic');

  const MeetingPlaceCoreSDKErrorCode(this.value);

  /// The wire value of this error code.
  final String value;
}
