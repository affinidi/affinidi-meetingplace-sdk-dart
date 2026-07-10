import 'package:meeting_place_core/meeting_place_core.dart';

/// Logger interface for Chat SDK
///
/// This interface allows consumers to provide their own logging implementation
/// to capture and handle SDK logs according to their needs.
abstract class MeetingPlaceChatSDKLogger implements MeetingPlaceCoreSDKLogger {
  /// Logs an informational message.
  ///
  /// [message] is the log content.
  /// [name] optionally specifies additional context/identifier.
  @override
  void info(String message, {String name = ''});

  /// Logs a warning message.
  ///
  /// [message] is the log content.
  /// [name] optionally specifies additional context/identifier.
  @override
  void warning(String message, {String name = ''});

  /// Logs an error message with details.
  ///
  /// [message] is the log content.
  /// [error] optionally provides an error or exception.
  /// [stackTrace] optionally provides the stack trace.
  /// [name] optionally specifies additional context/identifier.
  @override
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
  @override
  void debug(String message, {String name = ''});
}
