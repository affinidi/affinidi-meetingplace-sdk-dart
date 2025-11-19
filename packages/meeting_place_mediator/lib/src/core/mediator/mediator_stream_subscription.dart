import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

import '../../../meeting_place_mediator.dart';
import '../../constants/sdk_constants.dart';
import '../message/message_queue.dart';
import 'didcomm_types.dart';
import 'mediator_stream_data.dart';

class MediatorStreamSubscription {
  MediatorStreamSubscription({
    required MediatorClient client,
    required DidManager didManager,
    required Duration deleteMessageDelay,
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
  final Duration _deleteMessageDelay;
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

  void pushMessage(MediatorStreamData data) {
    final methodName = 'addMessage';
    if (_controller.isClosed) {
      _logger.warning('Stream is closed: data not pushed - ${data.message.id}',
          name: methodName);
      return;
    }

    if (!_controller.hasListener) {
      _logger.info('No listener detected. Event stored in buffer');
      _eventBuffer.add(data);
      return;
    }

    _controller.add(data);
    _logger.info('Data pushed to stream - ${data.message.id}',
        name: methodName);
  }

  MediatorStreamSubscription listen(
    FutureOr<void> Function(PlainTextMessage) onData, {
    void Function(Object e)? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _controller.stream.listen(
      (MediatorStreamData data) async {
        try {
          await onData(data.message);

          final type = data.message.type.toString();
          if (DidcommTypes.isEphemeral.contains(type) ||
              DidcommTypes.isTelemetery.contains(type)) {
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

          onError?.call(e);
        }
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    if (_eventBuffer.isEmpty) {
      return this;
    }

    // Flush buffered events to the stream once listener attaches
    _logger.info('Flush buffered event to the stream');
    for (var data in _eventBuffer) {
      _controller.add(data);
    }
    _eventBuffer.clear();

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
      final decryptedMessage = await DidcommMessage.unpackToPlainTextMessage(
        message: message,
        recipientDidManager: _didManager,
        expectedMessageWrappingTypes: _messageWrappingTypes,
      );

      pushMessage(MediatorStreamData(
        message: decryptedMessage,
        messageHash: _hashMessage(message),
      ));

      _logger.info('Completed processing incoming message', name: methodName);
      return;
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

  String _hashMessage(Map<String, dynamic> message) {
    return sha256.convert(utf8.encode(jsonEncode(message))).toString();
  }
}
