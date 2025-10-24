/// Enumeration representing different types of repository exceptions
/// that can occur in the Meeting Place Core SDK.
///
/// Values:
/// - [missingChannel]: Indicates that a required channel is missing.
/// - [missingConnectionOffer]: Indicates that a required connection offer is
/// missing.
/// - [missingGroup]: Indicates that a required group is missing.
/// - [missingMessage]: Indicates that a required message is missing.
/// - [unsupportedMessageType]: Indicates that the message type is unsupported.
/// - [unsupportedMessageType]: Indicates that the message type is unsupported.
enum MeetingPlaceCoreRepositoryErrorCode {
  /// Missing channel exception type.
  missingChannel('missing_channel'),

  /// Missing connection offer exception type.
  missingConnectionOffer('missing_connection_offer'),

  /// Missing group exception type.
  missingGroup('missing_group'),

  /// Missing message exception type.
  missingMessage('missing_message'),

  /// Unsupported message type exception.
  unsupportedMessageType('unsupported_message_type');

  const MeetingPlaceCoreRepositoryErrorCode(this.value);
  final String value;
}
