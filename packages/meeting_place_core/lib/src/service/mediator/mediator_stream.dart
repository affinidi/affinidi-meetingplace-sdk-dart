import 'dart:async';

import '../../../meeting_place_core.dart';

typedef OnDataCallback = void Function(MediatorMessage);

class MediatorStream {
  MediatorStream({
    required MediatorChannel mediatorChannel,
    required MeetingPlaceCoreSDKLogger logger,
  })  : _mediatorChannel = mediatorChannel,
        _logger = logger {
    _streamController = _controller;
  }

  final MediatorChannel _mediatorChannel;
  final MeetingPlaceCoreSDKLogger _logger;
  final List<MediatorMessage> _eventBuffer = <MediatorMessage>[];

  StreamController<MediatorMessage>? _streamController;

  Stream<MediatorMessage> get stream {
    return _controller.stream;
  }

  StreamController<MediatorMessage> get _controller {
    return _streamController ??= StreamController<MediatorMessage>.broadcast();
  }

  void pushData(MediatorMessage data) {
    if (_controller.isClosed) {
      _logger.info('Stream is closed -> event not pushed to stream');
      return;
    }

    if (!_controller.hasListener) {
      _logger.info('No listener detected. Event stored in buffer');
      _eventBuffer.add(data);
      return;
    }

    _logger.info(
      '''Push message of type ${data.plainTextMessage.toString()} to mediator stream.''',
    );
    _controller.add(data);
  }

  MediatorStream listen(
    OnDataCallback? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    _logger.info('Flush buffered event to the stream');
    for (var data in _eventBuffer) {
      _controller.add(data);
    }
    _eventBuffer.clear();

    return this;
  }

  Future<void> dispose() async {
    if (_controller.isClosed) {
      _logger.info('Stream already closed');
      return;
    }

    _logger.info('Dispose mediator stream');
    await _controller.close();
    await _mediatorChannel.dispose();
  }
}
