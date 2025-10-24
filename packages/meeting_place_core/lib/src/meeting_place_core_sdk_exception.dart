import '../meeting_place_core.dart';

/// The exception that is thrown when an error occurs in the
/// MeetingPlaceCoreSDKException.
///
/// The [SDKException] is intended to provide more context about where
/// the error originated by including the [method] name along with a
/// descriptive [message].
///
/// Example:
/// ```dart
/// void someSdkMethod() {
///   throw MeetingPlaceCoreSDKException(
///     'someSdkMethod',
///     'Something went wrong'
///   );
/// }
/// ```
class MeetingPlaceCoreSDKException implements Exception {
  /// Creates a [MeetingPlaceCoreSDKException] instance.
  MeetingPlaceCoreSDKException({
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

  @override
  String toString() {
    final buffer = StringBuffer()..writeln('$message (code: $code)');
    Object? current = innerException;

    while (current != null) {
      if (current is! MeetingPlaceMediatorSDKException &&
          current is! ControlPlaneSDKException) {
        buffer.writeln('- Caused by: ${current.toString()}');
      }
      current = getNestedInnerException(current);
    }
    return buffer.toString();
  }

  Object? getNestedInnerException(Object exception) {
    try {
      return (exception as dynamic).innerException;
    } catch (_) {
      return null;
    }
  }
}
