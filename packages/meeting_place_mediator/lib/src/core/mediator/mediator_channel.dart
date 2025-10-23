import 'dart:async';

import 'package:didcomm/didcomm.dart';

import '../../constants/sdk_constants.dart';
import '../../loggers/default_meeting_place_mediator_sdk_logger.dart';
import '../../loggers/meeting_place_mediator_sdk_logger.dart';
import 'mediator_session_client.dart';

typedef OnDataCallback = void Function(PlainTextMessage);

class MediatorChannel {
  MediatorChannel({
    required MediatorSessionClient sessionClient,
    MeetingPlaceMediatorSDKLogger? logger,
  })  : _sessionClient = sessionClient,
        _logger = logger ??
            DefaultMeetingPlaceMediatorSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'MediatorChannel';

  final MediatorSessionClient _sessionClient;
  final MeetingPlaceMediatorSDKLogger _logger;

  StreamController<PlainTextMessage>? _streamController;

  Stream<PlainTextMessage> get stream {
    return _controller.stream;
  }

  StreamController<PlainTextMessage> get _controller {
    return _streamController ??= StreamController<PlainTextMessage>.broadcast();
  }

  void addMessage(PlainTextMessage message) {
    final methodName = 'addMessage';
    _logger.info('Adding message to stream: ${message.id}', name: methodName);
    if (_controller.isClosed) {
      _logger.warning(
        'Stream is closed, event not pushed to stream: ${message.id}',
        name: methodName,
      );
      return;
    }

    _logger.info(
      'Completed adding message to stream: ${message.id}',
      name: methodName,
    );
    _controller.add(message);
  }

  StreamSubscription<PlainTextMessage> listen(OnDataCallback? onData) {
    return stream.listen(onData);
  }

  Future<void> dispose() async {
    final methodName = 'dispose';
    if (isClosed()) {
      _logger.warning('Stream already closed', name: methodName);
      return;
    }

    _logger.info('Closing stream', name: methodName);
    await _controller.close();

    await _sessionClient.disconnect();
  }

  bool isClosed() {
    return _controller.isClosed;
  }
}
