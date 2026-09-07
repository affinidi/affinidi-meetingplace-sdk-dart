import 'core/mediator/mediator_stream/mediator_stream_subscription.dart'
    show MediatorStreamSubscription;
import 'meeting_place_mediator_sdk_exception.dart'
    show MeetingPlaceMediatorSDKException;

/// Classifies the failure reported by a [MeetingPlaceMediatorSDKException].
enum MeetingPlaceMediatorSDKErrorCode {
  /// Updating an ACL on the mediator failed.
  updateAclError('mediator_update_acl_error'),

  /// Subscribing to the mediator's WebSocket stream failed.
  subscribeToWebsocketError('mediator_subscribe_to_websocket_error'),

  /// Sending a message to the mediator failed.
  sendMessageError('mediator_send_message_error'),

  /// Queueing a message for later delivery failed.
  queueMessageError('mediator_queue_message_error'),

  /// Authenticating with the mediator failed.
  authenticationError('mediator_authentication_error'),

  /// Deleting one or more messages from the mediator failed.
  deleteMessagesError('mediator_delete_messages_error'),

  /// An error occurred on an established WebSocket connection.
  websocketError('mediator_websocket_error'),

  /// Fetching the mediator's DID from its well-known endpoint failed.
  getMediatorDidError('mediator_get_did_error'),

  /// No matching key agreement could be found between the local and
  /// recipient DID documents.
  keyAgreementMismatch('mediator_key_agreement_mismatch'),

  /// Fetching an out-of-band (OOB) invitation from the mediator failed.
  oobError('mediator_oob_error'),

  /// A network error occurred while communicating with the mediator.
  networkError('mediator_network_error'),

  /// No command handler was registered for the dispatched command type.
  missingHandlerError('mediator_missing_handler_error'),

  /// The operation was attempted on a [MediatorStreamSubscription] that has
  /// already been closed.
  subscriptionClosedError('mediator_subscription_closed_error'),

  // others
  /// A fallback code used when the underlying error could not be mapped to
  /// a more specific code.
  generic('generic');

  const MeetingPlaceMediatorSDKErrorCode(this.value);

  /// The string identifier for this error code, used when serializing
  /// exceptions.
  final String value;
}
