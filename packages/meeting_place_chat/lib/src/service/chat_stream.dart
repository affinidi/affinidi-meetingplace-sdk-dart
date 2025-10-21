import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../constants/sdk_constants.dart';
import '../entity/chat_item.dart';
import '../loggers/chat_sdk_logger.dart';
import '../loggers/default_chat_sdk_logger.dart';

class StreamData {
  StreamData({this.plainTextMessage, this.chatItem});

  final PlainTextMessage? plainTextMessage;
  final ChatItem? chatItem;
}

class ChatStream {
  ChatStream({ChatSDKLogger? logger})
      : _logger = logger ??
            DefaultChatSdkLogger(className: _className, sdkName: sdkName);

  static const String _className = 'ChatStream';
  final List<StreamData> _eventBuffer = <StreamData>[];
  final ChatSDKLogger _logger;

  StreamController<StreamData>? _streamController;
  StreamController<StreamData> get _controller {
    return _streamController ??= StreamController<StreamData>.broadcast();
  }

  Stream<StreamData> get stream {
    return _controller.stream;
  }

  ChatStream listen(
    void Function(StreamData) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    // Flush buffered events to the stream once listener attaches
    _logger.info('Flush buffered event to the stream');
    for (var data in _eventBuffer) {
      _controller.add(data);
    }
    _eventBuffer.clear();

    return this;
  }

  void pushData(StreamData data) {
    final methodName = 'pushData';

    if (_controller.isClosed) {
      _logger.warning(
        'Stream is closed -> event not pushed to stream',
        name: methodName,
      );
      return;
    }

    if (!_controller.hasListener) {
      _logger.info('No listener detected. Event stored in buffer');
      _eventBuffer.add(data);
      return;
    }

    _logger.info('Add message to stream');
    _controller.add(data);
  }

  void dispose() {
    final methodName = 'dispose';

    if (_controller.isClosed) {
      _logger.warning('Stream already closed', name: methodName);
      return;
    }

    _logger.info('Closing stream', name: methodName);
    _controller.close();
  }

  void addError(Object e) {
    final methodName = 'addError';

    _logger.info(
      'Error while processing event -> ${e.toString()}',
      name: methodName,
    );
    _controller.addError(e);
  }
}
