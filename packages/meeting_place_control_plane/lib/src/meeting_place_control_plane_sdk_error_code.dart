/// Error codes carried by `MeetingPlaceControlPlaneSDKException` identifying
/// the specific failure that occurred while executing an SDK command.
enum MeetingPlaceControlPlaneSDKErrorCode {
  // accept offer codes
  /// Occurs when accepting an offer that has already been accepted.
  acceptOfferAlreadyAccepted('accept_offer_already_accepted'),

  /// Occurs when accepting an offer that has reached its maximum number of
  /// allowed acceptances.
  acceptOfferLimitExceeded('accept_offer_limit_exceeded'),

  /// Generic fallback for errors raised during the accept offer command.
  acceptOfferGeneric('accept_offer_generic'),

  // accept group offer codes
  /// Generic fallback for errors raised during the accept offer group
  /// command.
  acceptOfferGroupGeneric('accept_offer_group_generic'),

  // authenticate codes
  /// Occurs when the control plane API returns an empty authentication
  /// challenge for the DID being authenticated.
  authenticateEmptyChallengeReturned('authenticate_empty_challenge_returned'),

  /// Occurs when the authenticate response received from the control plane
  /// API contains invalid or unexpected data.
  authenticateInvalidResponseData('authenticate_invalid_response_data'),

  /// Generic fallback for errors raised during authentication.
  authenticateGeneric('authenticate_generic'),

  // oob codes
  /// Occurs when the requested out-of-band invitation cannot be found.
  oobNotFound('oob_not_found'),

  /// Generic fallback for errors raised while creating an out-of-band
  /// invitation.
  createOobGeneric('create_oob_generic'),

  // delete pending notifications codes
  /// Occurs when deleting pending notifications fails partway through,
  /// after some notifications have already been deleted.
  deletePendingNotificationsDeletionFailedError(
    'delete_pending_notifications_deletion_failed_error',
  ),

  /// Generic fallback for errors raised while deleting pending
  /// notifications.
  deletePendingNotificationsGeneric('delete_pending_notifications_generic'),

  // deregister notification codes
  /// Generic fallback for errors raised while deregistering a notification.
  deregisterNotificationGeneric('deregister_notification_generic'),

  // deregister offer codes
  /// Occurs when the control plane API returns an error response while
  /// deregistering an offer.
  deregisterOfferFailedError('deregister_offer_failed_error'),

  /// Generic fallback for errors raised while deregistering an offer.
  deregisterOfferGeneric('deregister_offer_generic'),

  // finalise acceptance codes
  /// Occurs when the control plane API returns an error response while
  /// finalising an offer acceptance.
  finaliseAcceptanceError('finalise_acceptance_error'),

  /// Generic fallback for errors raised while finalising an offer
  /// acceptance.
  finaliseAcceptanceGeneric('finalise_acceptance_generic'),

  // get pending notifications codes
  /// Occurs when a fetched pending notification has an invalid or empty
  /// payload.
  getPendingNotificationsNotificationPayloadError(
    'get_pending_notifications_notification_payload_error',
  ),

  /// Generic fallback for errors raised while fetching pending
  /// notifications.
  getPendingNotificationsGeneric('get_pending_notifications_generic'),

  // group add member codes
  /// Generic fallback for errors raised while adding a group member.
  groupAddMemberGeneric('group_add_member_generic'),

  // group delete codes
  /// Generic fallback for errors raised while deleting a group.
  groupDeleteGeneric('group_delete_generic'),

  // group notify channel codes
  /// Generic fallback for errors raised while notifying a group channel.
  groupNotifyChannelGeneric('group_notify_channel_generic'),

  // group deregister member codes
  /// Generic fallback for errors raised while deregistering a group member.
  groupDeregisterMemberGeneric('group_deregister_member_generic'),

  // notify acceptance codes
  /// Generic fallback for errors raised while notifying an offer
  /// acceptance.
  notifyAcceptanceGeneric('notify_acceptance_generic'),

  // notifyacceptance group codes
  /// Generic fallback for errors raised while notifying a group offer
  /// acceptance.
  notifyAcceptanceGroupGeneric('notify_acceptance_group_generic'),

  // notify channel codes
  /// Generic fallback for errors raised while notifying a channel.
  notifyChannelGeneric('notify_channel_generic'),

  // notify outreach codes
  /// Generic fallback for errors raised while notifying an outreach offer.
  notifyOutreachGeneric('notify_outreach_generic'),

  // query offer codes
  /// Generic fallback for errors raised while querying an offer.
  queryOfferOfferGeneric('query_offer_generic'),

  // register device codes
  /// Generic fallback for errors raised while registering a device.
  registerDeviceGeneric('register_device_generic'),

  // register notification codes
  /// Generic fallback for errors raised while registering a notification.
  registerNotificationGeneric('register_notification_generic'),

  // register offer codes
  /// Occurs when registering an offer without a mediator DID configured on
  /// the SDK instance.
  registerOfferMediatorNotSet('register_offer_mediator_not_set'),

  /// Occurs when registering an offer whose mnemonic phrase is already in
  /// use.
  registerOfferMnemonicInUse('register_offer_mnemonic_in_use'),

  /// Generic fallback for errors raised while registering an offer.
  registerOfferGeneric('register_offer_generic'),

  // register offer group codes
  /// Occurs when registering an offer group without a mediator DID
  /// configured on the SDK instance.
  registerOfferGroupMediatorNotSet('register_offer_group_mediator_not_set'),

  /// Occurs when registering an offer group whose mnemonic phrase is
  /// already in use.
  registerOfferGroupMnemonicInUse('register_offer_group_mnemonic_in_use'),

  /// Generic fallback for errors raised while registering an offer group.
  registerOfferGroupGeneric('register_offer_group_generic'),

  // validate offer phrase codes
  /// Occurs when the control plane API returns an authentication error
  /// (HTTP 401 or 403) while validating an offer phrase.
  validateOfferPhraseAuthentication('validate_offer_phrase_authentication'),

  /// Occurs when the control plane API returns a rate limit error
  /// (HTTP 429) while validating an offer phrase.
  validateOfferPhraseRateLimit('validate_offer_phrase_rate_limit'),

  /// Occurs when validating an offer phrase times out.
  validateOfferPhraseTimeout('validate_offer_phrase_timeout'),

  /// Generic fallback for errors raised while validating an offer phrase.
  validateOfferPhraseGeneric('validate_offer_phrase_generic'),

  // matrix token codes
  /// Occurs when the control plane API returns an invalid Matrix token
  /// response.
  matrixTokenInvalidResponse('matrix_token_invalid_response'),

  /// Generic fallback for errors raised while requesting a Matrix token.
  matrixTokenGeneric('matrix_token_generic'),

  // upload did document codes
  /// Generic fallback for errors raised while uploading a did:web DID
  /// Document.
  uploadDidWebDocumentGeneric('upload_did_web_document_generic'),

  /// Occurs when the control plane API returns HTTP 409 Conflict because a
  /// DID Document for this DID has already been registered.
  uploadDidWebDocumentAlreadyRegistered(
    'upload_did_web_document_already_registered',
  ),

  // device codes
  /// Occurs when `MeetingPlaceControlPlaneSDK.device` is accessed before a
  /// device has been set on the SDK instance.
  missingDevice('missing_device'),

  // others
  /// Occurs when a command fails due to a network error, such as a
  /// connection or timeout failure.
  networkError('network_error'),

  /// Generic fallback used when no other error code applies.
  generic('generic');

  const MeetingPlaceControlPlaneSDKErrorCode(this.value);

  /// The wire string representation of this error code.
  final String value;
}
