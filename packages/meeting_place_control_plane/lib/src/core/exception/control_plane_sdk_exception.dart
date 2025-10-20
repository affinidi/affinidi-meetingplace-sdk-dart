enum ControlPlaneSDKExceptionErrorCodes { generic }

/// Represents a control plane SDK exception.
class ControlPlaneSDKException implements Exception {
  /// Creates a [MpxSdkException] instance.
  ControlPlaneSDKException({
    required this.message,
    required this.code,
    required this.innerException,
  });

  /// The exception message.
  final String message;

  /// The exception code.
  final String code;

  /// The original exception
  final Object innerException;

  @override
  String toString() {
    final buffer = StringBuffer()..writeln('$message (code: $code)');
    Object? current = innerException;

    int depth = 1;
    while (current != null) {
      buffer.writeln('Caused by [$depth]: ${current.toString()}');

      current = getNestedInnerException(current);
      depth++;
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
