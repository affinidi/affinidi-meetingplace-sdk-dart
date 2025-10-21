/// A custom exception class for Meeting Place Core SDK repository errors.
class MeetingPlaceCoreRepositoryException implements Exception {
  /// Constructs a [MeetingPlaceCoreRepositoryException] with a message and type.
  ///
  /// **Parameters:**
  /// - [message]: A descriptive message for the exception.
  /// - [type]: The type of the exception as a string.
  MeetingPlaceCoreRepositoryException(this.message, {required this.type});

  /// The descriptive message for the exception.
  final String message;

  /// The type of the exception as a string.
  final String type;
}
