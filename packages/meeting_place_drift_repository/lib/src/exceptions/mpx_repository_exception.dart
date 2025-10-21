/// A custom exception class for Meeting Place repository errors.
class MpxRepositoryException implements Exception {
  /// Constructs a [MpxRepositoryException] with a message and type.
  ///
  /// **Parameters:**
  /// - [message]: A descriptive message for the exception.
  /// - [type]: The type of the exception as a string.
  MpxRepositoryException(this.message, {required this.type});

  /// The descriptive message for the exception.
  final String message;

  /// The type of the exception as a string.
  final String type;
}
