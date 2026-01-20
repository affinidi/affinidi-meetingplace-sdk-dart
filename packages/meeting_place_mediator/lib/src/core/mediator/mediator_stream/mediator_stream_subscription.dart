import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

import '../../../../meeting_place_mediator.dart';
import '../../../constants/sdk_constants.dart';
import '../../message/message_queue.dart';
import '../../message/message_unpacker.dart';
import '../../message/plaintext_message_extension.dart';
import 'mediator_stream_data.dart';

class MediatorStreamSubscription {
  MediatorStreamSubscription({
    required MediatorClient client,
    required DidManager didManager,
    required Duration? deleteMessageDelay,
    required List<MessageWrappingType> messageWrappingTypes,
    MeetingPlaceMediatorSDKLogger? logger,
  })  : _client = client,
        _didManager = didManager,
        _deleteMessageDelay = deleteMessageDelay,
        _messageWrappingTypes = messageWrappingTypes,
        _messageQueue = MessageQueue(client: client, logger: logger),
        _logger = logger ??
            DefaultMeetingPlaceMediatorSDKLogger(
              className: _className,
              sdkName: sdkName,
            );

  static const String _className = 'MediatorStreamSubscription';

  final MediatorClient _client;
  final DidManager _didManager;
  final Duration? _deleteMessageDelay;
  final List<MessageWrappingType> _messageWrappingTypes;
  final List<MediatorStreamData> _eventBuffer = <MediatorStreamData>[];
  final MessageQueue _messageQueue;
  final MeetingPlaceMediatorSDKLogger _logger;

  StreamController<MediatorStreamData>? _streamController;
  bool get isClosed => _controller.isClosed;

  Stream<MediatorStreamData> get stream => _controller.stream;
  StreamController<MediatorStreamData> get _controller =>
      _streamController ??= StreamController<MediatorStreamData>.broadcast();

  Future<void> initialize() async {
    const methodName = 'initialize';

    if (isClosed) {
      throw StateError('Cannot initialize a closed subscription');
    }

    try {
      _client.listenForIncomingMessages(
        _onIncomingMessage,
        onDone: _onDone,
      );

      await ConnectionPool.instance.startConnections();
      _logger.info('Mediator stream subscription initialized',
          name: methodName);
    } on StateError catch (e, stackTrace) {
      _logger.error('Mediator client already connected.',
          name: methodName, error: e, stackTrace: stackTrace);
    } catch (e) {
      rethrow;
    }
  }

  void _pushMessage(MediatorStreamData data) {
    final methodName = 'pushMessage';
    if (_controller.isClosed) {
      _logger.warning('Stream is closed: data not pushed - ${data.message.id}',
          name: methodName);
      return;
    }

    if (!_controller.hasListener) {
      _eventBuffer.add(data);
      _logger.info(
          'No listener detected. Event buffered (total: ${_eventBuffer.length})',
          name: methodName);
      return;
    }

    _controller.add(data);
    _logger.info('Data pushed to stream - ${data.message.id}',
        name: methodName);
  }

  MediatorStreamSubscription listen(
    FutureOr<void> Function(PlainTextMessage) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _controller.stream.listen(
      (MediatorStreamData data) async {
        try {
          await onData(data.message);

          if (data.message.isEphermeral || data.message.isTelemetry) {
            return;
          }

          _messageQueue.scheduleDeletion(data.messageHash,
              delay: _deleteMessageDelay);
        } catch (e, stackTrace) {
          _logger.error(
            '''Error while processing message of type:
            ${data.message.type.toString()}''',
            error: e,
            stackTrace: stackTrace,
            name: 'listen',
          );
          _controller.addError(e);
        }
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    if (_eventBuffer.isNotEmpty) {
      _logger.info(
          'Flushing ${_eventBuffer.length} buffered event(s) to the stream',
          name: 'listen');

      _eventBuffer.forEach(_controller.add);
      _eventBuffer.clear();
    }

    return this;
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
    final methodName = '_onIncomingMessage';

    try {
      final decryptedMessage = await MessageUnpacker.unpackWithRetry(
        message: message,
        recipientDidManager: _didManager,
        expectedMessageWrappingTypes: _messageWrappingTypes,
        onRetry: (e) => _logger.warning(
          'Retrying unpacking message due to error: $e',
          name: methodName,
        ),
      );

      _pushMessage(MediatorStreamData(
        message: decryptedMessage,
        messageHash: _hashMessage(message),
      ));

      _logger.info('Completed processing incoming message', name: methodName);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to process incoming message',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
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

  String _hashMessage(Map<String, dynamic> message) {
    return sha256.convert(utf8.encode(jsonEncode(message))).toString();
  }
}
