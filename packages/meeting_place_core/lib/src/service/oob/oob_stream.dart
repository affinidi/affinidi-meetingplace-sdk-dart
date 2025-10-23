import 'dart:async';

import '../../../meeting_place_core.dart';
import 'oob_stream_data.dart';

typedef OnDisposeCallback = FutureOr<void> Function();

class OobStream implements MediatorStreamSubscription<OobStreamData> {
  OobStream({
    OnDisposeCallback? onDispose,
    required MeetingPlaceCoreSDKLogger logger,
  })  : _onDispose = onDispose,
        _logger = logger;

  final OnDisposeCallback? _onDispose;
  final List<OobStreamData> _eventBuffer = <OobStreamData>[];
  final MeetingPlaceCoreSDKLogger _logger;

  StreamController<OobStreamData>? _streamController;
  Timer? _timeoutTimer;

  @override
  Stream<OobStreamData> get stream => _controller.stream;

  @override
  bool get isClosed => _controller.isClosed;

  StreamController<OobStreamData> get _controller =>
      _streamController ??= StreamController<OobStreamData>.broadcast();

  @override
  StreamSubscription<OobStreamData> listen(
    void Function(OobStreamData) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final streamSubscription = _controller.stream.listen(
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

    return streamSubscription;
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

  @override
  StreamSubscription<OobStreamData> timeout(
    Duration timeLimit,
    void Function()? onTimeout,
  ) {
    return stream
        .timeout(
          timeLimit,
          onTimeout: onTimeout != null
              ? (EventSink sink) {
                  try {
                    onTimeout();
                  } catch (e, stackTrace) {
                    _logger.error(
                      'Error in timeout callback',
                      error: e,
                      stackTrace: stackTrace,
                    );
                  }
                }
              : null,
        )
        .listen(null);
  }

  @override
  Future<void> dispose() async {
    _timeoutTimer?.cancel();

    if (_controller.isClosed) {
      _logger.info('Stream already closed');
      return;
    }

    _logger.info('Closing stream');
    await _controller.close();

    if (_onDispose != null) await _onDispose();
  }
}
