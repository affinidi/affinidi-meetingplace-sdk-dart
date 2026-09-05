import 'dart:developer' as developer;

import '../constants/sdk_constants.dart' as constants;
import 'meeting_place_control_plane_sdk_logger.dart';

/// Default console logger implementation using `dart:developer`.
///
/// This logger outputs logs to the console with a consistent format.
class DefaultMeetingPlaceControlPlaneSDKLogger
    implements MeetingPlaceControlPlaneSDKLogger {
  /// Creates a logger with an optional [className] identifying the logging
  /// source.
  ///
  /// [className] defaults to 'DefaultDiscoverySdkLogger'.
  /// [sdkName] is used as the log name in `dart:developer` and defaults to
  /// 'DISC_SDK'.
  DefaultMeetingPlaceControlPlaneSDKLogger({
    this.className = 'DefaultMeetingPlaceControlPlaneSDKLogger',
    this.sdkName = constants.sdkName,
  });

  final String className;
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
