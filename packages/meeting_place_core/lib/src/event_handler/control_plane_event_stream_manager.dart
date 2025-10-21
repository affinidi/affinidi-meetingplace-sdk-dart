import 'dart:async';

import '../loggers/default_mpx_sdk_logger.dart';
import '../loggers/mpx_sdk_logger.dart';
import 'control_plane_stream_event.dart';

class ControlPlaneEventStreamManager {
  ControlPlaneEventStreamManager({MeetingPlaceCoreSDKLogger? logger})
      : _logger =
            logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className) {
    _streamController = _controller;
  }

  static const String _className = 'DiscoveryEventStreamManager';

  final MeetingPlaceCoreSDKLogger _logger;
  StreamController<ControlPlaneStreamEvent>? _streamController;

  Stream<ControlPlaneStreamEvent> get stream {
    return _controller.stream;
  }

  StreamController<ControlPlaneStreamEvent> get _controller {
    return _streamController ??=
        StreamController<ControlPlaneStreamEvent>.broadcast();
  }

  void pushEvent(ControlPlaneStreamEvent event) {
    final methodName = 'pushEvent';

    if (_controller.isClosed) {
      _logger.warning(
        'Stream is closed -> event not pushed to stream',
        name: methodName,
      );
      return;
    }

    _logger.info('Add event to stream', name: methodName);
    _controller.add(event);
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
    _logger.error('Error while processing event', error: e, name: methodName);
    _controller.addError(e);
  }
}
