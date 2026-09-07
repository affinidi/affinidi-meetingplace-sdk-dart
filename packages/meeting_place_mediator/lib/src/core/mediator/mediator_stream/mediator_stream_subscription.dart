import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:didcomm/didcomm.dart';
import 'package:mutex/mutex.dart';
import 'package:ssi/ssi.dart';

import '../../../../meeting_place_mediator.dart';
import '../../../constants/sdk_constants.dart';
import '../../exception/sdk_exception_mapper.dart';
import '../../message/message_queue.dart';
import '../../message/message_unpacker.dart';
import '../../message/plaintext_message_extension.dart';
import '../mediator_exception.dart';
import 'mediator_stream_data.dart';

/// A live subscription to a mediator's WebSocket stream of incoming
/// messages, returned by [MeetingPlaceMediatorSDK.subscribeToMessages].
///
/// Once [initialize]d, this subscription decrypts incoming messages as they
/// arrive over the WebSocket connection and buffers them internally until a
/// listener is attached via [listen]. It automatically reconnects after an
/// abnormal disconnect, and reauthenticates via the [DidManager] supplied at
/// construction time as needed. Call [dispose] to close the connection and
/// release resources once the subscription is no longer needed.
class MediatorStreamSubscription {
  /// Creates a [MediatorStreamSubscription] that authenticates via
  /// [didManager] and receives messages over [client]'s WebSocket
  /// connection.
  ///
  /// - [deleteMessageDelay]: Delay before a processed message is deleted
  ///   from the mediator; `null` deletes it immediately.
  /// - [messageWrappingTypes]: The DIDComm message wrapping types expected
  ///   when unpacking incoming messages.
  /// - [logger]: Optional logger; defaults to a
  ///   [DefaultMeetingPlaceMediatorSDKLogger] when not provided.
  MediatorStreamSubscription({
    required MediatorClient client,
    required DidManager didManager,
    required Duration? deleteMessageDelay,
    required List<MessageWrappingType> messageWrappingTypes,
    MeetingPlaceMediatorSDKLogger? logger,
  }) : _client = client,
       _didManager = didManager,
       _deleteMessageDelay = deleteMessageDelay,
       _messageWrappingTypes = messageWrappingTypes,
       _messageQueue = MessageQueue(client: client, logger: logger),
       _logger =
           logger ??
           DefaultMeetingPlaceMediatorSDKLogger(
             className: _className,
             sdkName: sdkName,
           );

  static const String _className = 'MediatorStreamSubscription';
  static final Mutex _reconnectMutex = Mutex();

  final MediatorClient _client;
  final DidManager _didManager;
  final Duration? _deleteMessageDelay;
  final List<MessageWrappingType> _messageWrappingTypes;
  final List<MediatorStreamData> _eventBuffer = <MediatorStreamData>[];
  final MessageQueue _messageQueue;
  final MeetingPlaceMediatorSDKLogger _logger;

  StreamController<MediatorStreamData>? _streamController;

  /// Whether this subscription has been closed via [dispose].
  bool get isClosed => _controller.isClosed;

  /// The broadcast stream of decrypted incoming messages.
  ///
  /// Most consumers should use [listen] instead, since it also schedules
  /// message deletion and flushes any events buffered before a listener was
  /// attached.
  Stream<MediatorStreamData> get stream => _controller.stream;
  StreamController<MediatorStreamData> get _controller =>
      _streamController ??= StreamController<MediatorStreamData>.broadcast();

  /// Establishes the WebSocket connection to the mediator and starts
  /// listening for incoming messages.
  ///
  /// Throws a [MeetingPlaceMediatorSDKException] if this subscription has
  /// already been [dispose]d, or if establishing the connection fails for a
  /// reason other than the client already being connected.
  Future<void> initialize() async {
    const methodName = 'initialize';

    if (isClosed) {
      throw toMediatorSdkException(MediatorException.subscriptionClosedError());
    }

    try {
      _client.listenForIncomingMessages(_onIncomingMessage, onDone: _onDone);

      await ConnectionPool.instance.startConnections();
      _logger.info(
        'Mediator stream subscription initialized',
        name: methodName,
      );
    } on StateError catch (e, stackTrace) {
      _logger.error(
        'Mediator client already connected.',
        name: methodName,
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(toMediatorSdkException(e), stackTrace);
    }
  }

  void _pushMessage(MediatorStreamData data) {
    final methodName = 'pushMessage';
    if (_controller.isClosed) {
      _logger.warning(
        'Stream is closed: data not pushed - ${data.message.id}',
        name: methodName,
      );
      return;
    }

    if (!_controller.hasListener) {
      _eventBuffer.add(data);
      _logger.info(
        'No listener detected. Event buffered (total: '
        '${_eventBuffer.length})',
        name: methodName,
      );
      return;
    }

    _controller.add(data);
    _logger.info(
      'Data pushed to stream - ${data.message.id}',
      name: methodName,
    );
  }

  /// Subscribes [onData] to receive decrypted messages and schedules their
  /// deletion from the mediator once processed.
  ///
  /// For each incoming message, [onData] is invoked with the decrypted
  /// message; ephemeral and telemetry messages are delivered but never
  /// scheduled for deletion. For any other message, if the returned
  /// [MediatorStreamProcessingResult.keepMessage] is `false`, the message is
  /// scheduled for deletion from the mediator after the delay configured at
  /// construction time. If [onData] throws, the error is logged and
  /// re-emitted on the stream.
  ///
  /// [onError], [onDone], and [cancelOnError] are forwarded to the
  /// underlying stream subscription with their usual [Stream.listen]
  /// semantics.
  ///
  /// Any messages received before this method is first called are buffered
  /// internally and flushed to [onData] once a listener is attached.
  ///
  /// Returns this subscription to allow chaining.
  MediatorStreamSubscription listen(
    FutureOr<MediatorStreamProcessingResult> Function(PlainTextMessage)
    onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _controller.stream.listen(
      (MediatorStreamData data) async {
        try {
          final processingResult = await onData(data.message);

          if (data.message.isEphermeral || data.message.isTelemetry) {
            return;
          }

          if (!processingResult.keepMessage) {
            _messageQueue.scheduleDeletion(
              data.messageHash,
              delay: _deleteMessageDelay,
            );
          }
        } catch (e, stackTrace) {
          _logger.error(
            '''Error while processing message of type:
            ${data.message.type.toString()}''',
            error: e,
            stackTrace: stackTrace,
            name: 'listen',
          );
          _controller.addError(toMediatorSdkException(e), stackTrace);
        }
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    if (_eventBuffer.isNotEmpty) {
      _logger.info(
        'Flushing ${_eventBuffer.length} buffered event(s) to the stream',
        name: 'listen',
      );

      _eventBuffer.forEach(_controller.add);
      _eventBuffer.clear();
    }

    return this;
  }

  /// Closes the stream and disconnects the underlying WebSocket connection.
  ///
  /// Safe to call multiple times; calls after the first are a no-op.
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

      _pushMessage(
        MediatorStreamData(
          message: decryptedMessage,
          messageHash: _hashMessage(message),
        ),
      );

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

    final closeCodeDescription = _describeCloseCode(closeCode);
    _logger.info(
      'WebSocket disconnected - '
      'code: ${closeCode ?? "null"} ($closeCodeDescription), '
      'reason: ${closeReason ?? "none"}',
      name: methodName,
    );

    if (isClosed) {
      _logger.info(
        'Stream controller already closed (dispose was called), '
        'skipping reconnection attempt',
        name: methodName,
      );
      return;
    }

    if (closeCode == webSocketCloseNormal) {
      _logger.info(
        'Normal closure detected (code: $closeCode), '
        'session ended intentionally - not reconnecting',
        name: methodName,
      );
      return;
    }

    _logger.info(
      'Abnormal WebSocket closure detected - '
      'initiating automatic reconnection...',
      name: methodName,
    );

    await _reconnectMutex.protect(() async {
      try {
        _logger.info('Disconnecting stale client...', name: methodName);
        await _client.disconnect();
        _logger.info(
          'Stale client disconnected successfully',
          name: methodName,
        );
      } catch (e) {
        _logger.warning(
          'Non-fatal error during disconnect before reconnect: $e',
          name: methodName,
        );
      }

      if (isClosed) {
        _logger.info(
          'Stream controller closed during reconnect flow, aborting',
          name: methodName,
        );
        return;
      }

      try {
        _logger.info(
          'Re-establishing WebSocket connection...',
          name: methodName,
        );
        _client.listenForIncomingMessages(_onIncomingMessage, onDone: _onDone);

        await ConnectionPool.instance.startConnections();
        _logger.info(
          'WebSocket reconnection successful - '
          'now listening for incoming messages',
          name: methodName,
        );
      } on StateError catch (e, stackTrace) {
        _logger.error(
          'Reconnection failed: client already in connected state',
          name: methodName,
          error: e,
          stackTrace: stackTrace,
        );
      } catch (e, stackTrace) {
        _logger.error(
          'Reconnection failed unexpectedly: $e',
          name: methodName,
          error: e,
          stackTrace: stackTrace,
        );
      }
    });
  }

  //TODO: Remove this method when the connection issue has been resolved.
  String _describeCloseCode(int? code) {
    if (code == null) return 'TCP connection dropped without close frame';
    switch (code) {
      case webSocketCloseNormal:
        return 'Normal Closure';
      case webSocketCloseGoingAway:
        return 'Going Away';
      case 1002:
        return 'Protocol Error';
      case 1003:
        return 'Unsupported Data';
      case 1005:
        return 'No Status Received';
      case 1006:
        return 'Abnormal Closure';
      case 1007:
        return 'Invalid Payload Data';
      case 1008:
        return 'Policy Violation';
      case 1009:
        return 'Message Too Big';
      case 1010:
        return 'Mandatory Extension';
      case 1011:
        return 'Internal Server Error';
      case 1012:
        return 'Service Restart';
      case 1013:
        return 'Try Again Later';
      case 1015:
        return 'TLS Handshake Failure';
      default:
        return 'Unknown ($code)';
    }
  }

  String _hashMessage(Map<String, dynamic> message) {
    return sha256.convert(utf8.encode(jsonEncode(message))).toString();
  }
}
