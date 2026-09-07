/// Represents a Meeting Place Mediator SDK exception.
class MeetingPlaceMediatorSDKException implements Exception {
  /// Creates a [MeetingPlaceMediatorSDKException] instance.
  MeetingPlaceMediatorSDKException({
    required this.message,
    required this.code,
    required this.innerException,
  });

  /// The exception message.
  final String message;

  /// The code of the exception.
  final String code;

  /// The original exception
  final Object innerException;

  /// Formats this exception's message and code, followed by a line for
  /// [innerException] and each further nested inner exception found by
  /// walking [getNestedInnerException] until none remain.
  @override
  String toString() {
    final buffer = StringBuffer()..writeln('$message (code: $code)');
    Object? current = innerException;

    while (current != null) {
      buffer.writeln('- Caused by: ${current.toString()}');
      current = getNestedInnerException(current);
    }
    return buffer.toString();
  }

  /// Returns [exception]'s `innerException` field, if it has one and it is
  /// accessible dynamically, or `null` otherwise.
  Object? getNestedInnerException(Object exception) {
    try {
      return (exception as dynamic).innerException;
    } catch (_) {
      return null;
    }
  }
}
