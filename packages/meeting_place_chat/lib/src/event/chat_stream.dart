import 'dart:async';

import '../constants.dart';
import '../event/stream_data.dart';
import '../logger/default_meeting_place_chat_sdk_logger.dart';
import '../logger/meeting_place_chat_sdk_logger.dart';

/// A buffered, broadcast [Stream] of [StreamData] for a single chat.
///
/// Events pushed via [pushData] before any consumer is listening are
/// buffered and flushed to the stream once a listener attaches, so events
/// that arrive between a chat being opened and its UI subscribing are not
/// lost.
class ChatStream {
  /// Creates a [ChatStream].
  ///
  /// [logger] is an optional logger; defaults to a
  /// [DefaultMeetingPlaceChatSDKLogger] when not supplied.
  ChatStream({MeetingPlaceChatSDKLogger? logger})
    : _logger =
          logger ??
          DefaultMeetingPlaceChatSDKLogger(
            className: _className,
            sdkName: sdkName,
          );

  static const String _className = 'ChatStream';
  final List<StreamData> _eventBuffer = <StreamData>[];
  final MeetingPlaceChatSDKLogger _logger;
  bool _hasAttachedConsumer = false;

  StreamController<StreamData>? _streamController;
  StreamController<StreamData> get _controller {
    return _streamController ??= StreamController<StreamData>.broadcast(
      onListen: () {
        _hasAttachedConsumer = true;
        _flushBuffer();
      },
      onCancel: _resumeBufferingWhenNoListeners,
    );
  }

  void _resumeBufferingWhenNoListeners() {
    _hasAttachedConsumer = _streamController?.hasListener ?? false;
  }

  void _flushBuffer() {
    if (_eventBuffer.isEmpty) return;
    _logger.info('Flushing ${_eventBuffer.length} buffered event(s) to stream');
    final buffered = List<StreamData>.from(_eventBuffer);
    _eventBuffer.clear();
    for (final data in buffered) {
      _streamController?.add(data);
    }
  }

  /// The underlying broadcast stream of [StreamData].
  Stream<StreamData> get stream {
    return _controller.stream;
  }

  /// Subscribes [onData] (and optionally [onError], [onDone],
  /// [cancelOnError]) to [stream], flushing any buffered events first.
  ///
  /// Returns this [ChatStream] to allow chaining.
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

    return this;
  }

  /// Pushes [data] to [stream], or buffers it if no consumer is currently
  /// listening. No-ops if the stream has already been [dispose]d.
  void pushData(StreamData data) {
    final methodName = 'pushData';

    if (_controller.isClosed) {
      _logger.warning(
        'Stream is closed -> event not pushed to stream',
        name: methodName,
      );
      return;
    }

    if (!_hasAttachedConsumer) {
      _logger.info('No listener detected. Event stored in buffer');
      _eventBuffer.add(data);
      return;
    }

    _logger.info('Add message to stream');
    _controller.add(data);
  }

  /// Closes the underlying stream controller. No-ops if already closed.
  void dispose() {
    final methodName = 'dispose';

    if (_controller.isClosed) {
      _logger.warning('Stream already closed', name: methodName);
      return;
    }

    _logger.info('Closing stream', name: methodName);
    _controller.close();
  }

  /// Forwards [e] as an error event on [stream].
  void addError(Object e) {
    final methodName = 'addError';

    _logger.info(
      'Error while processing event -> ${e.toString()}',
      name: methodName,
    );
    _controller.addError(e);
  }
}
