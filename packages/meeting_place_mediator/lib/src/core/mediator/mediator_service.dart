import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:didcomm/didcomm.dart' hide ForwardMessage;
import 'package:dio/dio.dart';
import '../../constants/sdk_constants.dart';
import '../../loggers/default_mediator_sdk_logger.dart';
import '../../loggers/mediator_sdk_logger.dart';
import '../../protocol/message/oob_invitation_message.dart';
import '../../sdk/mediator_sdk_options.dart';
import '../../utils/base64.dart';
import '../../utils/didcomm.dart';
import '../../utils/string.dart';
import 'forward_message.dart';
import 'mediator_channel.dart';
import 'mediator_exception.dart';
import 'package:retry/retry.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../acl/acl_management.dart';
import '../acl/acl_body.dart';
import '../message/send_message_queue.dart';
import 'fetch_message_result.dart';
import 'mediator_session.dart';
import 'mediator_session_client.dart';
import 'unpack_message_exception.dart';

class MediatorService {
  MediatorService({
    required this.didResolver,
    required MediatorSDKOptions options,
    MediatorSdkLogger? logger,
  })  : _options = options,
        _logger = logger ??
            DefaultMediatorSdkLogger(className: _className, sdkName: sdkName);
  static const String _className = 'MediatorService';

  final SendMessageQueue sendMessageQueue = SendMessageQueue();
  final DidResolver didResolver;
  final MediatorSDKOptions _options;
  final Map<String, MediatorSessionClient> _sessions = {};
  final MediatorSdkLogger _logger;

  MediatorSessionClient? _activeSession;
  MediatorChannel? stream;

  Future<MediatorSessionClient> _connectToMediator({
    required DidManager didManager,
    required String mediatorDid,
    required SignatureScheme signatureScheme,
    bool reauthenticate = false,
  }) async {
    final methodName = '_connectToMediator';
    _logger.info(
      'Started connecting to mediator: ${mediatorDid.topAndTail()}',
      name: methodName,
    );

    final didDocument = await didManager.getDidDocument();
    final cacheKey = _cacheKey(mediatorDid: mediatorDid, did: didDocument.id);

    if (!reauthenticate && _sessions[cacheKey] != null) {
      _logger.info(
        'Reusing existing mediator session for cacheKey: $cacheKey',
        name: methodName,
      );
      return Future.value(_sessions[cacheKey]);
    }

    return retry(
      () async {
        _logger.info(
          'Establishing new connection to mediator: ${mediatorDid.topAndTail()}',
          name: methodName,
        );

        final mediatorDidDocument = await didResolver.resolveDid(mediatorDid);
        final authenticationKeyId = didDocument.authentication.first.id;

        final keyAgreementKeyId = didDocument.matchKeysInKeyAgreement(
            otherDidDocuments: [mediatorDidDocument]).first;

        final client = MediatorClient(
          mediatorDidDocument: mediatorDidDocument,
          didKeyId: keyAgreementKeyId,
          keyPair: await didManager.getKeyPairByDidKeyId(keyAgreementKeyId),
          signer: await didManager.getSigner(authenticationKeyId),
          forwardMessageOptions: const ForwardMessageOptions(
            shouldSign: true,
            shouldEncrypt: true,
            keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
            encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
          ),
          webSocketOptions: WebSocketOptions(
            pingIntervalInSeconds: _options.websocketPingInterval,
            deleteOnMediator: false,
            statusRequestMessageOptions: StatusRequestMessageOptions(
              shouldSend: true,
              shouldSign: true,
              shouldEncrypt: true,
            ),
            liveDeliveryChangeMessageOptions: LiveDeliveryChangeMessageOptions(
              shouldSend: true,
              shouldSign: true,
              shouldEncrypt: true,
            ),
          ),
        );

        final session = MediatorSessionClient(
          id: didDocument.id,
          client: client,
          didManager: didManager,
          mediatorDid: mediatorDid,
          logger: _logger,
        );

        _sessions[cacheKey] = session;
        _activeSession = session;

        _logger.info(
          'Completed connecting to mediator: ${mediatorDid.topAndTail()}',
          name: methodName,
        );
        return Future.value(session);
      },
      retryIf: (e) {
        _logger.warning('Retrying due to error: $e', name: methodName);
        return e is SocketException || e is TimeoutException;
      },
      onRetry: (e) =>
          _logger.warning('Retry attempt due to: $e', name: methodName),
      delayFactor: _options.delayFactor,
      maxAttempts: _options.maxRetryAttempts,
    );
  }

  String _cacheKey({required String mediatorDid, required String did}) {
    return '$mediatorDid$did';
  }

  Future<MediatorSessionClient> authenticateWithDid({
    required DidManager didManager,
    required String mediatorDid,
    bool reauthenticate = false,
  }) async {
    final methodName = 'authenticateWithDid';
    _logger.info(
      'Started authenticating as DID with mediator: ${mediatorDid.topAndTail()}',
      name: methodName,
    );

    try {
      final didDocument = await didManager.getDidDocument();
      final cacheKey = _cacheKey(mediatorDid: mediatorDid, did: didDocument.id);

      final session = !reauthenticate && _sessions[cacheKey] != null
          ? _sessions[cacheKey]
          : await _connectToMediator(
              didManager: didManager,
              mediatorDid: mediatorDid,
              signatureScheme: SignatureScheme.ecdsa_p256_sha256,
              reauthenticate: reauthenticate,
            );

      if (!reauthenticate &&
          session?.session is MediatorSession &&
          session!.session!.isValid()) {
        _logger.info(
          'Reusing mediator session for ${didDocument.id.topAndTail()}',
          name: methodName,
        );
        _activeSession = session;
        _logger.info(
          'Successfully reused mediator session for ${didDocument.id.topAndTail()}',
          name: methodName,
        );
        return session;
      }

      return retry(
        () async {
          final authTokens = await session!.client.authenticate();
          session.createSession(
            accessToken: authTokens.accessToken,
            accessExpiresAt: authTokens.accessExpiresAt,
            refreshToken: authTokens.refreshToken,
            refreshExpiresAt: authTokens.refreshExpiresAt,
            secondsBeforeExpiryReauthenticate:
                _options.secondsBeforeExpiryReauthenticate,
          );

          _sessions[cacheKey] = session;
          _activeSession = session;

          _logger.info(
            'Completed authentication as ${session.id.topAndTail()}',
            name: methodName,
          );
          return session;
        },
        maxAttempts: _options.maxRetryAttempts,
        delayFactor: _options.delayFactor,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to authenticate as DID with mediator: ${mediatorDid.topAndTail()}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        MediatorException.authenticationError(innerException: e),
        stackTrace,
      );
    }
  }

  Future<String> createOob(DidManager didManager, String mediatorDid) async {
    final methodName = 'createOob';
    _logger.info('Started creating OOB invitation', name: methodName);
    final session = await authenticateWithDid(
      didManager: didManager,
      mediatorDid: mediatorDid,
    );

    final didDoc = await didManager.getDidDocument();
    final message = OobInvitationMessage.create(from: didDoc.id);

    _logger.info('Completed creating OOB invitation', name: methodName);
    return session.client.createOob(message, accessToken: session.accessToken!);
  }

  Future<String> getOob({
    required Uri oobUrl,
    required DidManager didManager,
  }) async {
    final methodName = 'getOob';
    final response = await Dio().get(oobUrl.toString());
    _logger.info('Fetched OOB invitation from $oobUrl', name: methodName);
    return response.data['data'];
  }

  Future<void> sendMessage(
    PlainTextMessage message, {
    required DidManager senderDidManager,
    required DidDocument recipientDidDocument,
    required String mediatorDid,
    required String next,
    bool ephemeral = false,
    int? forwardExpiryInSeconds,
  }) async {
    final methodName = 'sendMessage';
    _logger.info('Started sending message', name: methodName);

    try {
      final session = await authenticateWithDid(
        didManager: senderDidManager,
        mediatorDid: mediatorDid,
      );

      final encryptedMessage = await signAndEncryptMessage(
        message,
        senderDidManager: senderDidManager,
        recipientDidDocument: recipientDidDocument,
      );

      _logger.info(
        'Sending message ${message.type.toString()} from ${session.id.topAndTail()} to ${next.topAndTail()}. Forwarding via ${session.client.mediatorDidDocument.id.topAndTail()}',
        name: methodName,
      );

      final expiresTime = forwardExpiryInSeconds != null
          ? DateTime.now().toUtc().add(
                Duration(seconds: forwardExpiryInSeconds),
              )
          : null;

      await session.client.sendMessage(
        ForwardMessage(
          id: const Uuid().v4(),
          from: session.id,
          to: [session.client.mediatorDidDocument.id],
          next: next,
          ephemeral: ephemeral,
          expiresTime: expiresTime,
          attachments: [
            Attachment(
              mediaType: 'application/json',
              data: AttachmentData(
                base64: removePaddingFromBase64(
                  base64UrlEncode(utf8.encode(jsonEncode(encryptedMessage))),
                ),
              ),
            ),
          ],
        ),
        accessToken: session.accessToken,
      );

      _logger.info(
        'Message sent from ${session.id.topAndTail()} to ${next.topAndTail()}. Forwarding via ${session.client.mediatorDidDocument.id.topAndTail()}',
        name: methodName,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to send message from ${message.from?.topAndTail()} to ${next.topAndTail()}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        MediatorException.sendMessageError(innerException: e),
        stackTrace,
      );
    }
  }

  Future<void> queueMessage(
    PlainTextMessage message, {
    required DidManager senderDidManager,
    required DidDocument recipientDidDocument,
    required String mediatorDid,
    required String next,
    bool? ephemeral,
    int? forwardExpiryInSeconds,
  }) async {
    final methodName = 'queueMessage';
    _logger.info('Started queuing message', name: methodName);

    try {
      final session = await authenticateWithDid(
        didManager: senderDidManager,
        mediatorDid: mediatorDid,
      );

      _logger.info(
        'Queuing message from ${session.id.topAndTail()} to ${next.topAndTail()}. Forwarding via ${session.client.mediatorDidDocument.id.topAndTail()}',
        name: methodName,
      );

      sendMessageQueue.add(
        QueueItem(
          message: message,
          senderDidManager: senderDidManager,
          mediatorDid: mediatorDid,
          next: next,
        ),
      );

      sendMessageQueue.scheduleAction((item) {
        return sendMessage(
          item.message,
          senderDidManager: item.senderDidManager,
          recipientDidDocument: recipientDidDocument,
          mediatorDid: item.mediatorDid,
          next: item.next,
          ephemeral: ephemeral ?? false,
          forwardExpiryInSeconds: forwardExpiryInSeconds,
        );
      }, 3);
      _logger.info(
        'Message queued from ${session.id.topAndTail()} to ${next.topAndTail()}. Forwarding via ${session.client.mediatorDidDocument.id.topAndTail()}',
        name: methodName,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to queue message from ${message.from?.topAndTail()} to ${next.topAndTail()}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        MediatorException.queueMessageError(innerException: e),
        stackTrace,
      );
    }
  }

  Future<MediatorChannel> subscribe({
    required DidManager didManager,
    required String mediatorDid,
    bool reauthenticate = false,
    bool deleteOnMediator = true,
    List<MessageWrappingType> messageWrappingTypes = const [
      MessageWrappingType.authcryptSignPlaintext,
    ],
  }) async {
    final methodName = 'subscribe';
    _logger.info('Started subscribing to websocket', name: methodName);

    try {
      MediatorSessionClient sessionClient = await authenticateWithDid(
        didManager: didManager,
        mediatorDid: mediatorDid,
        reauthenticate: reauthenticate,
      );

      final stream = MediatorChannel(
        sessionClient: sessionClient,
        logger: _logger,
      );

      Future<bool> onMessage(PlainTextMessage message) {
        stream.addMessage(message);
        return Future.value(true);
      }

      await sessionClient.openReceiveChannel(
        messageWrappingTypes: messageWrappingTypes,
        onMessage: onMessage,
        deleteOnMediator: deleteOnMediator,
        onDone: (int? closeCode) async {
          await _onReceiveChannelClosed(
            closeCode,
            onMessage: onMessage,
            didManager: didManager,
            mediatorDid: mediatorDid,
            messageWrappingTypes: messageWrappingTypes,
            deleteOnMediator: deleteOnMediator,
          );
        },
      );

      _logger.info(
        'Completed subscribing to websocket for mediator: ${mediatorDid.topAndTail()}',
        name: methodName,
      );
      return stream;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to subscribe to websocket for mediator: ${mediatorDid.topAndTail()}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        MediatorException.subscribeToWebsocketError(innerException: e),
        stackTrace,
      );
    }
  }

  Future<void> updateAcl({
    required DidManager ownerDidManager,
    required String mediatorDid,
    required AclBody acl,
  }) async {
    final methodName = 'updateAcl';
    _logger.info('Started updating ACL', name: methodName);

    try {
      final session = await authenticateWithDid(
        didManager: ownerDidManager,
        mediatorDid: mediatorDid,
      );

      await _activeSession!.client.sendAclManagementMessage(
        AclManagement(
          from: session.id,
          to: [session.client.mediatorDidDocument.id],
          body: acl,
        ),
        accessToken: session.accessToken,
      );

      _logger.info(
        'Updated ACL for owner ${session.id.topAndTail()} on resource ${mediatorDid.topAndTail()}',
        name: methodName,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to update ACL for resource ${mediatorDid.topAndTail()}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        MediatorException.updateAclError(acl: acl, innerException: e),
        stackTrace,
      );
    }
  }

  Future<List<FetchMessageResult>> fetch({
    required DidManager didManager,
    required String mediatorDid,
    bool deleteOnRetrieve = false,
    DateTime? startFrom,
    int? fetchMessagesBatchSize,
    int? maxResults,
  }) async {
    final methodName = 'fetch';
    _logger.info('Started fetching messages', name: methodName);

    final session = await authenticateWithDid(
      didManager: didManager,
      mediatorDid: mediatorDid,
    );

    // TODO: improve performance by using streams
    final mediatorMessages = await _fetchMediatorMessages(
      session: session,
      messages: [],
      deleteOnRetrieve: deleteOnRetrieve,
      startFrom: startFrom,
      fetchMessagesBatchSize: fetchMessagesBatchSize,
      maxResults: maxResults,
    );

    return Future.wait(
      mediatorMessages.map((mediatorMessage) async {
        try {
          final result = await FetchMessageResult.fromMessage(
            mediatorMessage,
            didManager: didManager,
          );

          _logger.info(
            '''Process message of type ${result.message?.type.toString()} for ${session.id.topAndTail()} from ${session.client.mediatorDidDocument.id.topAndTail()}''',
            name: methodName,
          );

          return result;
        } on UnpackMessageException catch (e, stackTrace) {
          _logger.error(
            'Failed to fetch message for ${session.id.topAndTail()} via ${session.client.mediatorDidDocument.id.topAndTail()}',
            error: e,
            stackTrace: stackTrace,
            name: methodName,
          );
          return Future.value(
            FetchMessageResult(
              messageHash: e.messageHash.toString(),
              error: e.innerException.toString(),
            ),
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Error processing mediator message',
            error: e,
            stackTrace: stackTrace,
            name: methodName,
          );
          rethrow;
        }
      }),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMediatorMessages({
    required MediatorSessionClient session,
    required List<Map<String, dynamic>> messages,
    bool deleteOnRetrieve = false,
    DateTime? startFrom,
    int? fetchMessagesBatchSize,
    int? maxResults,
  }) async {
    final useBatchSize = fetchMessagesBatchSize ?? 25;
    final result = await session.client.fetchMessagesStartingFrom(
      accessToken: session.accessToken,
      deleteOnMediator: deleteOnRetrieve,
      batchSize: useBatchSize,
      startFrom: startFrom,
    );

    messages.addAll(result);
    return messages;

    // TODO: pagination
    // if (result.length < useBatchSize ||
    //     (maxResults != null && messages.length >= maxResults)) {
    //   return messages;
    // }

    // return _fetchMediatorMessages(
    //   session: session,
    //   messages: messages,
    //   deleteOnRetrieve: deleteOnRetrieve,
    //   fetchMessagesBatchSize: fetchMessagesBatchSize,
    //   maxResults: maxResults,
    //   startId: messages.last.receiveId,
    // );
  }

  Future<void> delete({
    required DidManager didManager,
    required String mediatorDid,
    required List<String> messageHashes,
  }) async {
    final methodName = 'delete';
    _logger.info('Started deleting messages', name: methodName);
    final session = await authenticateWithDid(
      didManager: didManager,
      mediatorDid: mediatorDid,
    );

    await session.client.deleteMessages(
      messageIds: messageHashes,
      accessToken: session.accessToken,
    );

    _logger.info(
      'Completed deleting ${messageHashes.length} message(s) from mediator ${mediatorDid.topAndTail()}',
      name: methodName,
    );
  }

  Future<String> getMediatorDidFromUrl(String mediatorEndpoint) async {
    final methodName = 'getMediatorDidFromUrl';
    _logger.info(
      'Started resolving mediator DID from URL: $mediatorEndpoint',
      name: methodName,
    );

    if (mediatorEndpoint.endsWith('/')) {
      mediatorEndpoint = mediatorEndpoint.substring(
        0,
        mediatorEndpoint.length - 1,
      );
    }

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await dio.get(
        '$mediatorEndpoint/.well-known/did',
        options: Options(headers: {'CONTENT-TYPE': 'application/json'}),
      );

      final mediatorDid = response.data['data'] as String;
      _logger.info(
        'Completed resolving mediator DID is $mediatorDid',
        name: methodName,
      );
      return mediatorDid;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to resolve mediator DID from URL: $mediatorEndpoint',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        MediatorException.getMediatorDidError(
          mediatorEndpoint: mediatorEndpoint,
          innerException: e,
        ),
        stackTrace,
      );
    }
  }

  Future<void> _onReceiveChannelClosed(
    int? closeCode, {
    required DidManager didManager,
    required String mediatorDid,
    required List<MessageWrappingType> messageWrappingTypes,
    required OnMessageCallback onMessage,
    required bool deleteOnMediator,
  }) async {
    final methodName = '_onReceiveChannelClosed';
    _logger.info(
      'Started handling websocket receive channel closed with code: $closeCode',
      name: methodName,
    );

    if (closeCode != null) {
      final sessionClient = await authenticateWithDid(
        didManager: didManager,
        mediatorDid: mediatorDid,
      );

      _logger.info('Open new websocket connection', name: methodName);
      await sessionClient.openReceiveChannel(
        messageWrappingTypes: messageWrappingTypes,
        onMessage: onMessage,
        deleteOnMediator: deleteOnMediator,
        onDone: (closeCode) async {
          await _onReceiveChannelClosed(
            closeCode,
            onMessage: onMessage,
            didManager: didManager,
            mediatorDid: mediatorDid,
            messageWrappingTypes: messageWrappingTypes,
            deleteOnMediator: deleteOnMediator,
          );
        },
      );
    }
    _logger.info('Completed handling receive channel closed', name: methodName);
  }
}
