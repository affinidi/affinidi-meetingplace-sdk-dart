/// Logger interface for Discovery SDK
///
/// This interface allows consumers to provide their own logging implementation
/// to capture and handle SDK logs according to their needs.
abstract class ControlPlaneSDKLogger {
  /// Logs an informational message.
  ///
  /// [message] is the log content.
  /// [name] optionally specifies additional context/identifier.
  void info(String message, {String name = ''});

  /// Logs a warning message.
  ///
  /// [message] is the log content.
  /// [name] optionally specifies additional context/identifier.
  void warning(String message, {String name = ''});

  /// Logs an error message with details.
  ///
  /// [message] is the log content.
  /// [error] optionally provides an error or exception.
  /// [stackTrace] optionally provides the stack trace.
  /// [name] optionally specifies additional context/identifier.
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = '',
  });

  /// Logs a debug message.
  ///
  /// [message] is the log content.
  /// [name] optionally specifies additional context/identifier.
  void debug(String message, {String name = ''});
}
