import 'dart:developer' as developer;

import '../constants.dart' as constants;
import 'meeting_place_matrix_sdk_logger.dart';

/// Default console logger for the Matrix SDK using `dart:developer`.
class DefaultMeetingPlaceMatrixSDKLogger
    implements MeetingPlaceMatrixSDKLogger {
  DefaultMeetingPlaceMatrixSDKLogger({
    this.className = 'DefaultMatrixSdkLogger',
    this.sdkName = constants.sdkName,
  });

  /// Name prefixed to every log message, identifying the logging component.
  final String className;

  /// The `dart:developer` log `name` used to group these log entries.
  final String sdkName;

  String _formatMessage(String message, String? method) {
    final methodSection = method != null ? '[$method] ' : '';
    return '[$className] $methodSection$message';
  }

  @override
  void info(String message, {String name = ''}) {
    developer.log('[INFO] ${_formatMessage(message, name)}', name: sdkName);
  }

  @override
  void warning(String message, {String name = ''}) {
    developer.log('[WARNING] ${_formatMessage(message, name)}', name: sdkName);
  }

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = '',
  }) {
    developer.log(
      '[ERROR] ${_formatMessage(message, name)}',
      name: sdkName,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void debug(String message, {String name = ''}) {
    assert(() {
      developer.log('[DEBUG] ${_formatMessage(message, name)}', name: sdkName);
      return true;
    }());
  }
}
