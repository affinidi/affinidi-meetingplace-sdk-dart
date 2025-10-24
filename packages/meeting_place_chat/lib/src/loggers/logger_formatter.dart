import '../constants/sdk_constants.dart' as constants;
import 'meeting_place_chat_sdk_logger.dart';
import 'default_meeting_place_chat_sdk_logger.dart';

/// Enhanced logger that automatically formats messages with SDK/class/method context
class LoggerFormatter implements MeetingPlaceChatSDKLogger {
  LoggerFormatter({
    required this.className,
    MeetingPlaceChatSDKLogger? baseLogger,
    this.sdkName = constants.sdkName,
  }) : _baseLogger = baseLogger ??
            DefaultMeetingPlaceChatSDKLogger(className: className);

  final String className;
  final String sdkName;
  final MeetingPlaceChatSDKLogger _baseLogger;

  String _formatName(String? methodName) {
    final method = methodName?.isNotEmpty == true ? '[$methodName]' : '';
    return '[$sdkName][$className]$method';
  }

  @override
  void info(String message, {String name = ''}) {
    _baseLogger.info(message, name: _formatName(name));
  }

  @override
  void warning(String message, {String name = ''}) {
    _baseLogger.warning(message, name: _formatName(name));
  }

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = '',
  }) {
    _baseLogger.error(
      message,
      error: error,
      stackTrace: stackTrace,
      name: _formatName(name),
    );
  }

  @override
  void debug(String message, {String name = ''}) {
    _baseLogger.debug(message, name: _formatName(name));
  }
}
