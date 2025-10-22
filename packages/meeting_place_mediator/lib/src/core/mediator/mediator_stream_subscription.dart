import 'dart:async';

import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

import '../../constants/sdk_constants.dart';
import '../../loggers/default_mediator_sdk_logger.dart';
import '../../loggers/mediator_sdk_logger.dart';

class MediatorStreamSubscription {
  MediatorStreamSubscription({
    required MediatorClient client,
    required DidManager didManager,
    required List<MessageWrappingType> messageWrappingTypes,
    MediatorSdkLogger? logger,
  })  : _client = client,
        _didManager = didManager,
        _messageWrappingTypes = messageWrappingTypes,
        _logger = logger ??
            DefaultMediatorSdkLogger(
              className: _className,
              sdkName: sdkName,
            );

  static const String _className = 'MediatorStreamSubscription';

  final MediatorClient _client;
  final DidManager _didManager;
  final List<MessageWrappingType> _messageWrappingTypes;
  final MediatorSdkLogger _logger;

  StreamController<PlainTextMessage>? _streamController;
  final List<PlainTextMessage> _eventBuffer = <PlainTextMessage>[];

  Stream<PlainTextMessage> get stream => _controller.stream;
  bool get isClosed => _controller.isClosed;
  StreamController<PlainTextMessage> get _controller =>
      _streamController ??= StreamController<PlainTextMessage>.broadcast();

  Future<void> initialize() async {
    const methodName = 'initialize';

    if (isClosed) {
      // TODO: StreamSubscriptionException
      throw Exception('Cannot initialize a closed subscription');
    }

    _client.listenForIncomingMessages(
      _onIncomingMessage,
      onDone: _onDone,
    );

    _logger.info('Mediator stream subscription initialized', name: methodName);
    await ConnectionPool.instance.startConnections();
  }

  void pushMessage(PlainTextMessage message) {
    final methodName = 'addMessage';
    if (_controller.isClosed) {
      _logger.warning('Stream is closed: message not pushed - ${message.id}',
          name: methodName);
      return;
    }

    if (!_controller.hasListener) {
      _logger.info('No listener detected. Event stored in buffer');
      _eventBuffer.add(message);
      return;
    }

    _controller.add(message);
    _logger.info('Message pushed to stream - ${message.id}', name: methodName);
  }

  Future<StreamSubscription<PlainTextMessage>> listen(
    void Function(PlainTextMessage) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) async {
    final subscription = _controller.stream.listen(
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

    return subscription;
  }

  Future<void> dispose() async {
    final methodName = 'dispose';

    if (isClosed) {
      _logger.warning('Stream already closed', name: methodName);
      return;
    }

    _logger.info('Closing stream', name: methodName);
    await _controller.close();
    await _client.disconnect();

    _logger.info('Mediator stream subscription disposed', name: methodName);
  }

  Future<void> _onIncomingMessage(Map<String, dynamic> message) async {
    try {
      final decryptedMessage = await DidcommMessage.unpackToPlainTextMessage(
        message: message,
        recipientDidManager: _didManager,
        expectedMessageWrappingTypes: _messageWrappingTypes,
      );

      pushMessage(decryptedMessage);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to process incoming message: ',
        error: e,
        stackTrace: stackTrace,
        name: '_onIncomingMessage',
      );
    }
  }

  void _onDone({int? closeCode, String? closeReason}) async {
    final methodName = '_onDone';

    _logger.info('Received web socket close code: $closeCode',
        name: methodName);

    if (closeCode == null) {
      _logger.info('Close code is null, done', name: methodName);
      return;
    }

    await _client.disconnect();
    _client.listenForIncomingMessages(
      _onIncomingMessage,
      onDone: _onDone,
    );

    await ConnectionPool.instance.startConnections();
    _logger.info('Re-subscribed to incoming messages', name: methodName);
  }
}
