import 'dart:async';

import 'package:meeting_place_mediator/meeting_place_mediator.dart'
    as mediator_sdk;
import '../../loggers/meeting_place_core_sdk_logger.dart';
import '../../repository/key_repository.dart';
import 'mediator_message.dart';
import '../core_sdk_stream_subscription.dart';

/// Wrapper around MediatorStreamSubscription that provides transformed
/// mediator messages like decrypting group messages.
class MediatorStreamSubscriptionWrapper
    implements CoreSDKStreamSubscription<MediatorMessage> {
  MediatorStreamSubscriptionWrapper({
    required mediator_sdk.MediatorStreamSubscription baseSubscription,
    required KeyRepository keyRepository,
    required MeetingPlaceCoreSDKLogger logger,
  })  : _baseSubscription = baseSubscription,
        _keyRepository = keyRepository,
        _logger = logger;

  final mediator_sdk.MediatorStreamSubscription _baseSubscription;
  final KeyRepository _keyRepository;
  final MeetingPlaceCoreSDKLogger _logger;

  StreamController<MediatorMessage>? _controller;

  /// Check if the underlying subscription is closed
  @override
  bool get isClosed => _baseSubscription.isClosed;

  /// Stream of transformed mediator messages
  @override
  Stream<MediatorMessage> get stream {
    _initializeStreamTransformation();
    return _controller!.stream;
  }

  @override
  StreamSubscription<MediatorMessage> listen(
    void Function(MediatorMessage) onData, {
    Function(Object e)? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return stream.listen(
      (message) {
        try {
          onData(message);
        } catch (e, stackTrace) {
          _logger.error(
            'Error in message handler',
            error: e,
            stackTrace: stackTrace,
            name: 'listen',
          );
          if (onError != null) {
            onError(e);
          } else {
            rethrow;
          }
        }
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  StreamSubscription<MediatorMessage> timeout(
    Duration timeLimit,
    void Function()? onTimeout,
  ) {
    return stream
        .timeout(timeLimit,
            onTimeout: onTimeout != null
                ? (sink) => _handleTimeout(onTimeout, sink)
                : null)
        .listen(null);
  }

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

  void _initializeStreamTransformation() {
    if (_controller != null) return;
    _controller = StreamController<MediatorMessage>.broadcast();
    _subscribeToBaseStream();
  }

  void _subscribeToBaseStream() {
    _baseSubscription.listen(
      (plainTextMessage) async {
        try {
          final mediatorMessage = await MediatorMessage.fromPlainTextMessage(
            plainTextMessage,
            keyRepository: _keyRepository,
          );

          if (!_controller!.isClosed) {
            _controller!.add(mediatorMessage);
          }
        } catch (e, stackTrace) {
          _logger.error('Error processing mediator message',
              error: e, stackTrace: stackTrace, name: 'stream');

          if (!_controller!.isClosed) {
            _controller!.addError(e, stackTrace);
          }
        }
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

  /// Dispose the subscription and close the connection
  @override
  Future<void> dispose() async {
    _logger.info('Disposing mediator message subscription');
    if (_controller != null && !_controller!.isClosed) {
      await _controller!.close();
    }
    await _baseSubscription.dispose();
  }
}
