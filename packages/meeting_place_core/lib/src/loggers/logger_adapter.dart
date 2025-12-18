import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';

import '../../meeting_place_core.dart';

class LoggerAdapter<T>
    implements
        MeetingPlaceCoreSDKLogger,
        ControlPlaneSDKLogger,
        MeetingPlaceMediatorSDKLogger {
  LoggerAdapter({
    required this.className,
    required this.sdkName,
    required T logger,
  }) : _logger = logger;

  final String className;
  final String sdkName;
  final T _logger;

  @override
  void info(String message, {String name = ''}) {
    if (_logger is MeetingPlaceCoreSDKLogger) {
      (_logger as MeetingPlaceCoreSDKLogger).info(
        message,
        name: _formatName(name),
      );
    } else if (_logger is ControlPlaneSDKLogger) {
      (_logger as ControlPlaneSDKLogger).info(message, name: _formatName(name));
    } else if (_logger is MeetingPlaceMediatorSDKLogger) {
      (_logger as MeetingPlaceMediatorSDKLogger).info(
        message,
        name: _formatName(name),
      );
    }
  }

  @override
  void warning(String message, {String name = ''}) {
    if (_logger is MeetingPlaceCoreSDKLogger) {
      (_logger as MeetingPlaceCoreSDKLogger).warning(
        message,
        name: _formatName(name),
      );
    } else if (_logger is ControlPlaneSDKLogger) {
      (_logger as ControlPlaneSDKLogger).warning(
        message,
        name: _formatName(name),
      );
    } else if (_logger is MeetingPlaceMediatorSDKLogger) {
      (_logger as MeetingPlaceMediatorSDKLogger).warning(
        message,
        name: _formatName(name),
      );
    }
  }

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = '',
  }) {
    if (_logger is MeetingPlaceCoreSDKLogger) {
      (_logger as MeetingPlaceCoreSDKLogger).error(
        message,
        error: error,
        stackTrace: stackTrace,
        name: _formatName(name),
      );
    } else if (_logger is ControlPlaneSDKLogger) {
      (_logger as ControlPlaneSDKLogger).error(
        message,
        error: error,
        stackTrace: stackTrace,
        name: _formatName(name),
      );
    } else if (_logger is MeetingPlaceMediatorSDKLogger) {
      (_logger as MeetingPlaceMediatorSDKLogger).error(
        message,
        error: error,
        stackTrace: stackTrace,
        name: _formatName(name),
      );
    }
  }

  @override
  void debug(String message, {String name = ''}) {
    if (_logger is MeetingPlaceCoreSDKLogger) {
      (_logger as MeetingPlaceCoreSDKLogger).debug(
        message,
        name: _formatName(name),
      );
    } else if (_logger is ControlPlaneSDKLogger) {
      (_logger as ControlPlaneSDKLogger).debug(
        message,
        name: _formatName(name),
      );
    } else if (_logger is MeetingPlaceMediatorSDKLogger) {
      (_logger as MeetingPlaceMediatorSDKLogger).debug(
        message,
        name: _formatName(name),
      );
    }
  }

  String _formatName(String? methodName) {
    final method = methodName?.isNotEmpty == true ? '[$methodName]' : '';
    return '[$sdkName][$className]$method';
  }
}
