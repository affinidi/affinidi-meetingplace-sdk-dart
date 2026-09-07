/// Error codes carried by `MeetingPlaceChatSDKException`, letting consumers
/// branch on the specific failure without parsing message text.
enum MeetingPlaceChatSDKErrorCode {
  /// No channel exists for the chat's `otherPartyDid`.
  channelNotFound('chat_channel_not_found'),

  /// A `senderDid` passed to an operation is neither participant of the
  /// chat.
  invalidParticipant('chat_invalid_participant'),

  /// An operation that requires the local contact card was called before one
  /// was set.
  missingContactCard('chat_missing_contact_card'),

  /// The operation is not supported by this chat implementation or
  /// transport (e.g. group-only operations on an individual chat).
  operationNotSupported('chat_operation_not_supported'),

  // others
  generic('generic');

  const MeetingPlaceChatSDKErrorCode(this.value);

  /// The wire-stable string representation of this code.
  final String value;
}
