import 'dart:async';
import 'dart:convert';

import '../../../meeting_place_mediator.dart';
import '../../utils/string.dart';
import 'didcomm_types.dart';
import 'package:crypto/crypto.dart';
import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import '../message/message_queue.dart';
import 'mediator_session.dart';

typedef OnMessageCallback = Future<bool> Function(PlainTextMessage message);
typedef OnDoneCallback = void Function(int? closeCode);

class MediatorSessionClient {
  MediatorSessionClient({
    required this.id,
    required this.client,
    required this.didManager,
    required this.mediatorDid,
    MediatorSdkLogger? logger,
  }) : _logger = logger ??
            DefaultMediatorSdkLogger(className: _className, sdkName: sdkName);
  static int processQueueDelayInSeconds = 3;
  static const String _className = 'MediatorSessionClient';

  final MediatorSdkLogger _logger;

  final String id;
  final MediatorClient client;
  final DidManager didManager;
  final String mediatorDid;

  final MessageQueue deletionQueue = MessageQueue();

  MediatorSession? session;

  String? get accessToken => session?.accessToken;

  void createSession({
    required String accessToken,
    required DateTime accessExpiresAt,
    required String refreshToken,
    required DateTime refreshExpiresAt,
    required int? secondsBeforeExpiryReauthenticate,
  }) {
    final methodName = 'createSession';
    _logger.info('Started creating new Mediator session', name: methodName);
    session = MediatorSession(
      accessToken: accessToken,
      accessExpiresAt: accessExpiresAt,
      refreshToken: refreshToken,
      refreshExpiresAt: refreshExpiresAt,
      secondsBeforeExpiryReauthenticate: secondsBeforeExpiryReauthenticate,
    );
  }

  Future<void> disconnect() {
    final methodName = 'disconnect';
    _logger.info('Disconnecting from mediator', name: methodName);
    return client.disconnect();
  }

  Future<void> openReceiveChannel({
    required List<MessageWrappingType> messageWrappingTypes,
    required OnMessageCallback onMessage,
    required Function(int? closeCode) onDone,
    required bool deleteOnMediator,
  }) async {
    final methodName = 'openReceiveChannel';
    _logger.info('Started opening websocket receive channel', name: methodName);

    await client.listenForIncomingMessages(
      (message) => _onMessage(
        message,
        onMessage,
        messageWrappingTypes,
        deleteOnMediator,
      ),
      onDone: ({int? closeCode, String? closeReason}) {
        _logger.info(
          'WebSocket connection closed.\nCode: ${closeCode ?? 'unknown'}\nReason: ${closeReason ?? 'unspecified'}',
          name: methodName,
        );
        onDone(closeCode);
      },
      onError: (err, stackTrace) {
        _logger.error(
          'Failed to connect to websocket',
          error: err,
          stackTrace: stackTrace,
          name: methodName,
        );
        Error.throwWithStackTrace(
          MediatorException.websocketError(innerException: err),
          stackTrace,
        );
      },
      accessToken: session?.accessToken,
    );

    _logger.info(
      'Completed opening websocket receive channel',
      name: methodName,
    );
  }

  void closeReceiveChannel() async {
    final methodName = 'closeReceiveChannel';
    _logger.info('Closing websocket connection', name: methodName);
    await client.disconnect();
    _logger.info('Completed closing websocket connection', name: methodName);
  }

  Future<void> _onMessage(
    Map<String, dynamic> message,
    OnMessageCallback onMessage,
    List<MessageWrappingType> messageWrappingTypes,
    bool deleteOnMediator,
  ) async {
    final methodName = '_onMessage';
    _logger.info('Started processing incoming message', name: methodName);

    try {
      final decryptedMessage = await DidcommMessage.unpackToPlainTextMessage(
        message: message,
        recipientDidManager: didManager,
        expectedMessageWrappingTypes: messageWrappingTypes,
      );

      final success = await onMessage(decryptedMessage);
      if (success && deleteOnMediator) {
        final type = decryptedMessage.type.toString();
        if (DidcommTypes.isEphemeral.contains(type) ||
            DidcommTypes.isTelemetery.contains(type)) {
          return;
        }

        final messageHash = _hashMessage(message);
        deletionQueue.add(messageHash);

        deletionQueue.scheduleAction((List<String> hashes) async {
          _logger.info(
            'Deleting ${hashes.length} message(s) for session ${id.topAndTail()}...',
            name: methodName,
          );

          await client.deleteMessages(
            messageIds: hashes,
            accessToken: accessToken,
          );
        }, processQueueDelayInSeconds);

        _logger.info('Completed processing incoming message', name: methodName);
        return;
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to process message: type=${message['type']},'
        ' from=${message['from']}, to=${message['to']}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
    }
  }

  String _hashMessage(Map<String, dynamic> message) {
    return sha256.convert(utf8.encode(jsonEncode(message))).toString();
  }
}
