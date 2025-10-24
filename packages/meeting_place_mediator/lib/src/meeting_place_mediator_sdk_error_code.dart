enum MeetingPlaceMediatorSDKErrorCode {
  updateAclError('mediator_update_acl_error'),
  subscribeToWebsocketError('mediator_subscribe_to_websocket_error'),
  sendMessageError('mediator_send_message_error'),
  queueMessageError('mediator_queue_message_error'),
  authenticationError('mediator_authentication_error'),
  deleteMessagesError('mediator_delete_messages_error'),
  websocketError('mediator_websocket_error'),
  getMediatorDidError('mediator_get_did_error'),
  keyAgreementMismatch('mediator_key_agreement_mismatch'),

  // others
  generic('generic');

  const MeetingPlaceMediatorSDKErrorCode(this.value);
  final String value;
}
