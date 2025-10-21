import 'dart:async';

import '../../loggers/meeting_place_core_sdk_logger.dart';
import 'oob_stream_data.dart';

typedef OnDisposeCallback = FutureOr<void> Function();

class OobStream {
  OobStream(
      {OnDisposeCallback? onDispose, required MeetingPlaceCoreSDKLogger logger})
      : _onDispose = onDispose,
        _logger = logger {
    _streamController = _controller;
  }

  final OnDisposeCallback? _onDispose;
  final List<OobStreamData> _eventBuffer = <OobStreamData>[];
  final MeetingPlaceCoreSDKLogger _logger;

  StreamController<OobStreamData>? _streamController;
  Timer? _timeoutTimer;

  Stream<OobStreamData> get stream {
    return _controller.stream;
  }

  StreamController<OobStreamData> get _controller {
    return _streamController ??= StreamController<OobStreamData>.broadcast();
  }

  OobStream listen(
    void Function(OobStreamData) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _controller.stream.listen(
      (event) {
        _timeoutTimer?.cancel();
        onData(event);
      },
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

  void pushEvent(OobStreamData data) {
    if (_controller.isClosed) {
      _logger.info('Event skipped due to closed stream');
      return;
    }

    if (!_controller.hasListener) {
      _logger.info('No listener detected. Event stored in buffer');
      _eventBuffer.add(data);
      return;
    }

    _logger.info('Push event to stream');
    _controller.add(data);
  }

  OobStream timeout(Duration timeLimit, void Function()? fn) {
    if (fn != null) {
      _timeoutTimer = Timer(timeLimit, () async {
        fn();
        await dispose();
      });
    }
    return this;
  }

  FutureOr<void> dispose() async {
    if (_controller.isClosed) {
      _logger.info('Stream already closed');
      return;
    }

    _logger.info('Closing stream');
    await _controller.close();

    if (_onDispose != null) await _onDispose();
  }
}
