enum ControlPlaneSDKErrorCode {
  // accept offer codes
  acceptOfferAlreadyAccepted('accept_offer_already_accepted'),
  acceptOfferLimitExceeded('accept_offer_limit_exceeded'),
  acceptOfferGeneric('accept_offer_generic'),

  // accept group offer codes
  acceptOfferGroupGeneric('accept_offer_group_generic'),

  // authenticate codes
  authenticateEmptyChallengeReturned('authenticate_empty_challenge_returned'),
  authenticateInvalidResponseData('authenticate_invalid_response_data'),
  authenticateGeneric('authenticate_generic'),

  // oob codes
  createOobGeneric('create_oob_generic'),

  // delete pending notifications codes
  deletePendingNotificationsDeletionFailedError(
      'delete_pending_notifications_deletion_failed_error'),
  deletePendingNotificationsGeneric('delete_pending_notifications_generic'),

  // deregister notification codes
  deregisterNotificationGeneric('deregister_notification_generic'),

  // deregister offer codes
  deregisterOfferFailedError('deregister_offer_failed_error'),
  deregisterOfferGeneric('deregister_offer_generic'),

  // finalise acceptance codes
  finaliseAcceptanceError('finalise_acceptance_error'),
  finaliseAcceptanceGeneric('finalise_acceptance_generic'),

  // get pending notifications codes
  getPendingNotificationsNotificationPayloadError(
      'get_pending_notifications_notification_payload_error'),
  getPendingNotificationsGeneric('get_pending_notifications_generic'),

  // group add member codes
  groupAddMemberGeneric('group_add_member_generic'),

  // group delete codes
  groupDeleteGeneric('group_delete_generic'),

  // group deregister member codes
  groupDeregisterMemberGeneric('group_deregister_member_generic'),

  // group deregister member codes
  groupSendMessageGeneric('group_send_message_generic'),

  // notify acceptance codes
  notifyAcceptanceGeneric('notify_acceptance_generic'),

  // notifyacceptance group codes
  notifyAcceptanceGroupGeneric('notify_acceptance_group_generic'),

  // notify channel codes
  notifyChannelGeneric('notify_channel_generic'),

  // notify outreach codes
  notifyOutreachGeneric('notify_outreach_generic'),

  // query offer codes
  queryOfferOfferGeneric('query_offer_generic'),

  // register device codes
  registerDeviceGeneric('register_device_generic'),

  // register notification codes
  registerNotificationGeneric('register_notification_generic'),

  // register offer codes
  registerOfferMediatorNotSet('register_offer_mediator_not_set'),
  registerOfferGeneric('register_offer_generic'),

  // register offer group codes
  registerOfferGroupMediatorNotSet('register_offer_group_mediator_not_set'),
  registerOfferGroupGeneric('register_offer_group_generic'),

  // validate offer phrase codes
  validateOfferPhraseAuthentication('validate_offer_phrase_authentication'),
  validateOfferPhraseRateLimit('validate_offer_phrase_rate_limit'),
  validateOfferPhraseTimeout('validate_offer_phrase_timeout'),
  validateOfferPhraseGeneric('validate_offer_phrase_generic'),

  // others
  networkError('network_error'),
  generic('generic');

  const ControlPlaneSDKErrorCode(this.value);
  final String value;
}
