/// Enum of exception types for MPX repository.
///
/// Values:
/// - [missingChannel]: Indicates that a requested channel was not found.
/// - [missingConnectionOffer]: Indicates that a requested connection offer was
/// not found.
/// - [missingGroup]: Indicates that a requested group was not found.
/// - [missingMessage]: Indicates that a requested message was not found.
/// - [unsupportedMessageType]: Indicates that the message type is unsupported.
enum MpxRepositoryExceptionType {
  missingChannel,
  missingConnectionOffer,
  missingGroup,
  missingMessage,
  unsupportedMessageType,
}
