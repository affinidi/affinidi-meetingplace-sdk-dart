/// Enumeration representing different types of repository exceptions
/// that can occur in the Meeting Place SDK.
///
/// Values:
/// - [missingChannel]: Indicates that a required channel is missing.
/// - [missingConnectionOffer]: Indicates that a required connection offer is
/// missing.
/// - [missingGroup]: Indicates that a required group is missing.
/// - [missingMessage]: Indicates that a required message is missing.
/// - [unsupportedMessageType]: Indicates that the message type is unsupported.
/// - [unsupportedMessageType]: Indicates that the message type is unsupported.
enum MpxRepositoryExceptionType {
  /// Missing channel exception type.
  missingChannel,

  /// Missing connection offer exception type.
  missingConnectionOffer,

  /// Missing group exception type.
  missingGroup,

  /// Missing message exception type.
  missingMessage,

  /// Unsupported message type exception.
  unsupportedMessageType,
}
