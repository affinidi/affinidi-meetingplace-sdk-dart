import '../constants/sdk_constants.dart' as constants;
import 'chat_sdk_logger.dart';
import 'default_chat_sdk_logger.dart';

/// Enhanced logger that automatically formats messages with SDK/class/method context
class LoggerFormatter implements ChatSDKLogger {
  LoggerFormatter({
    required this.className,
    ChatSDKLogger? baseLogger,
    this.sdkName = constants.sdkName,
  }) : _baseLogger = baseLogger ?? DefaultChatSdkLogger(className: className);

  final String className;
  final String sdkName;
  final ChatSDKLogger _baseLogger;

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
