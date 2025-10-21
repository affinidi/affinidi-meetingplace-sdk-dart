/// Class representing exceptions in the MPX repository.
class MpxRepositoryException implements Exception {
  /// A constructor for [MpxRepositoryException].
  ///
  /// **Parameters:**
  /// - [message]: A descriptive message for the exception.
  /// - [type]: The type of the exception as a string.
  MpxRepositoryException(this.message, {required this.type});

  /// A descriptive message for the exception.
  final String message;

  /// The type of the exception as a string.
  final String type;
}
