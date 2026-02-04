import 'dart:async';

import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import '../../loggers/meeting_place_core_sdk_logger.dart';
import '../../repository/key_repository.dart';
import 'mediator_message.dart';
import '../core_sdk_stream_subscription.dart';

/// Wrapper around MediatorStreamSubscription that provides transformed
/// mediator messages like decrypting group messages.
///
/// This wrapper transforms raw [PlainTextMessage] objects from the mediator
/// into [MediatorMessage] objects, handling group message decryption and
/// enrichment with metadata.
///
/// ## Multi-Listener Support
///
/// The wrapper uses a broadcast stream controller to support multiple
/// listeners. When multiple listeners are attached:
/// - Each listener receives the same transformed message
/// - Each listener's callback returns a [MediatorStreamProcessingResult]
/// - The message is deleted if **any** listener's result indicates deletion
///
/// ## Message Deletion Control
///
/// Listeners return a [MediatorStreamProcessingResult] from their `onData`
/// callback with a `keepMessage` property:
/// - `keepMessage: false`: Allow message deletion
/// - `keepMessage: true`: Keep the message (prevent deletion)
///
/// The wrapper coordinates all listeners using completers to ensure all have
/// finished processing before making the deletion decision. The message is
/// deleted if any listener returns a result with `keepMessage: false`.
/// If any listener throws an error, that listener's decision counts as
/// "keep message" (deletion prevented).
///
/// ## Lifecycle
///
/// The base subscription is initialized lazily when the stream is first
/// accessed. Call [dispose] to clean up resources when done.
class MediatorStreamSubscriptionWrapper
    implements
        CoreSDKStreamSubscription<
          MediatorMessage,
          MediatorStreamProcessingResult
        > {
  MediatorStreamSubscriptionWrapper({
    required MediatorStreamSubscription baseSubscription,
    required KeyRepository keyRepository,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _baseSubscription = baseSubscription,
       _keyRepository = keyRepository,
       _logger = logger;

  final MediatorStreamSubscription _baseSubscription;
  final KeyRepository _keyRepository;
  final MeetingPlaceCoreSDKLogger _logger;

  StreamController<MediatorMessage>? _controller;
  final Map<String, List<bool>> _messageProcessingResults = {};
  final Map<String, Completer<void>> _messageProcessingCompleters = {};
  final Map<String, int> _activeListenerCounts = {};
  int _listenerCount = 0;

  /// Check if the underlying subscription is closed
  @override
  bool get isClosed => _baseSubscription.isClosed;

  /// Stream of transformed mediator messages
  @override
  Stream<MediatorMessage> get stream {
    _initializeStreamTransformation();
    return _controller!.stream;
  }

  /// Listen to the stream of messages.
  ///
  /// **Parameters**:
  /// - [onData]: Callback for each message that returns whether to delete it.
  /// - [onError]: Optional error handler.
  /// - [onDone]: Optional completion handler.
  /// - [cancelOnError]: Whether to cancel on error.
  ///
  /// Returns a [StreamSubscription] for the listener.
  @override
  StreamSubscription<MediatorMessage> listen(
    FutureOr<MediatorStreamProcessingResult> Function(MediatorMessage) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _listenerCount++;

    final processingMessageIds = <String>{};

    final inner = stream.listen(
      (message) async {
        final messageId = message.plainTextMessage.id;
        processingMessageIds.add(messageId);

        try {
          final result = await onData(message);

          _messageProcessingResults.putIfAbsent(messageId, () => []);
          _messageProcessingResults[messageId]!.add(result.keepMessage);
        } catch (e, stackTrace) {
          _logger.error(
            'Error in message handler',
            error: e,
            stackTrace: stackTrace,
            name: 'listen',
          );

          if (!_controller!.isClosed) {
            _controller!.addError(e, stackTrace);
          }

          _messageProcessingResults.putIfAbsent(messageId, () => []);
          _messageProcessingResults[messageId]!.add(false);
        } finally {
          processingMessageIds.remove(messageId);
          _decrementActiveListenerCount(messageId);
        }
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    return _ListenerCountedSubscription(
      inner,
      onCancel: () {
        if (_listenerCount > 0) {
          _listenerCount--;
        }

        for (final messageId in _activeListenerCounts.keys.toList()) {
          if (!processingMessageIds.contains(messageId)) {
            _decrementActiveListenerCount(messageId);
          }
        }
      },
    );
  }

  /// Apply a timeout to the stream subscription
  @override
  StreamSubscription<MediatorMessage> timeout(
    Duration timeLimit,
    void Function()? onTimeout,
  ) {
    return stream
        .timeout(
          timeLimit,
          onTimeout: onTimeout != null
              ? (sink) => _handleTimeout(onTimeout, sink)
              : null,
        )
        .listen(null);
  }

  /// Dispose the subscription and close the connection
  @override
  Future<void> dispose() async {
    _logger.info('Disposing mediator message subscription');
    if (_controller != null && !_controller!.isClosed) {
      await _controller!.close();
    }
    await _baseSubscription.dispose();
  }

  /// Handle timeout by invoking the provided callback
  void _handleTimeout(
    void Function() onTimeout,
    EventSink<MediatorMessage> sink,
  ) {
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

  /// Initialize the stream transformation and set up the broadcast controller.
  ///
  /// This method is called lazily when the stream is first accessed. It creates
  /// a broadcast controller and subscribes to the base stream to transform
  /// [PlainTextMessage] objects into [MediatorMessage] objects.
  ///
  /// The method coordinates multiple listeners by:
  /// - Creating a completer for each message to wait for all listeners
  /// - Tracking active listener counts per message
  /// - Collecting deletion decisions from all listeners
  /// - Deleting messages if any listener requests deletion
  void _initializeStreamTransformation() {
    if (_controller != null) return;
    _controller = StreamController<MediatorMessage>.broadcast();

    // Set up the base subscription connection
    _subscribeToBaseStream(
      (message) async {
        final messageId = message.plainTextMessage.id;
        final completer = _trackMessage(messageId);

        if (!_controller!.isClosed) {
          _controller!.add(message);
        }

        // Wait for all listeners to finish processing
        if (_listenerCount > 0) {
          await completer.future;
        }

        final processingResults = _messageProcessingResults[messageId];
        _disposeMessageTracking(messageId);

        if (processingResults == null || processingResults.isEmpty) {
          return MediatorStreamProcessingResult(
            keepMessage: false,
          ); // Default: delete
        }

        return MediatorStreamProcessingResult(
          keepMessage: processingResults.every((keepMessage) => keepMessage),
        );
      },
      onError: (e) {
        if (!_controller!.isClosed) {
          _controller!.addError(e);
        }
      },
      onDone: () {
        if (!_controller!.isClosed) {
          _controller!.close();
        }
      },
    );
  }

  /// Track a new message by creating its completer and active listener count
  /// for coordinating multiple listeners.
  // Create a completer for this message and track expected listeners
  Completer<void> _trackMessage(String messageId) {
    final completer = Completer<void>();
    _messageProcessingCompleters[messageId] = completer;
    _activeListenerCounts[messageId] = _listenerCount;
    return completer;
  }

  /// Untrack a message by removing its completer and active listener count
  /// after processing is complete.
  void _disposeMessageTracking(String messageId) {
    _messageProcessingCompleters.remove(messageId);
    _activeListenerCounts.remove(messageId);
    _messageProcessingResults.remove(messageId);
  }

  /// Decrement the active listener count for a message and complete its
  /// processing completer when all listeners have finished
  void _decrementActiveListenerCount(String messageId) {
    final activeCount = _activeListenerCounts[messageId];
    if (activeCount == null) return;

    final remaining = activeCount - 1;
    if (remaining > 0) {
      _activeListenerCounts[messageId] = remaining;
      return;
    }

    // All listeners have processed this message
    final completer = _messageProcessingCompleters[messageId];
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  /// Subscribe to base subscription with transformation logic. The base
  /// subscription will handle message deletion based on return value
  ///
  /// **Parameters**:
  /// - [onData]: Callback for each message that returns whether to delete it.
  /// - [onError]: Optional error handler.
  /// - [onDone]: Optional completion handler.
  ///
  void _subscribeToBaseStream(
    FutureOr<MediatorStreamProcessingResult> Function(MediatorMessage) onData, {
    Function? onError,
    void Function()? onDone,
  }) {
    _baseSubscription.listen(
      (plainTextMessage) async {
        try {
          final mediatorMessage = await MediatorMessage.fromPlainTextMessage(
            plainTextMessage,
            keyRepository: _keyRepository,
            logger: _logger,
          );

          return await onData(mediatorMessage);
        } catch (e, stackTrace) {
          _logger.error(
            'Error processing mediator message',
            error: e,
            stackTrace: stackTrace,
            name: '_subscribeToBaseStream',
          );
          rethrow;
        }
      },
      onError: onError,
      onDone: onDone,
    );
  }
}

class _ListenerCountedSubscription<T> implements StreamSubscription<T> {
  _ListenerCountedSubscription(
    this._inner, {
    required void Function() onCancel,
  }) : _onCancel = onCancel;

  final StreamSubscription<T> _inner;
  final void Function() _onCancel;
  var _didCancel = false;

  @override
  Future<void> cancel() async {
    if (!_didCancel) {
      _didCancel = true;
      _onCancel();
    }
    await _inner.cancel();
  }

  @override
  Future<E> asFuture<E>([E? futureValue]) => _inner.asFuture(futureValue);

  @override
  bool get isPaused => _inner.isPaused;

  @override
  void onData(void Function(T data)? handleData) => _inner.onData(handleData);

  @override
  void onDone(void Function()? handleDone) => _inner.onDone(handleDone);

  @override
  void onError(Function? handleError) => _inner.onError(handleError);

  @override
  void pause([Future<void>? resumeSignal]) => _inner.pause(resumeSignal);

  @override
  void resume() => _inner.resume();
}
