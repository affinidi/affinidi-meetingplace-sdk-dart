import 'dart:async';

import 'package:didcomm/didcomm.dart';
import 'package:dio/dio.dart';
import '../../constants/sdk_constants.dart';
import '../../loggers/default_meeting_place_mediator_sdk_logger.dart';
import '../../loggers/meeting_place_mediator_sdk_logger.dart';
import '../../protocol/message/oob_invitation_message.dart';
import '../../meeting_place_mediator_sdk_options.dart';
import '../../utils/didcomm.dart';
import '../../utils/error_handler_utils.dart';
import '../../utils/string.dart';
import 'forward_message_builder.dart';
import 'mediator_stream/mediator_stream_subscription.dart';
import 'mediator_exception.dart';
import 'package:retry/retry.dart';
import 'package:ssi/ssi.dart';

import '../acl/acl_management.dart';
import '../acl/acl_body.dart';
import '../message/send_message_queue.dart';
import 'fetch_message_result.dart';
import 'unpack_message_exception.dart';

typedef OnMessageCallback = Future<bool> Function(PlainTextMessage message);

class MediatorService {
  MediatorService({
    required this.didResolver,
    required MeetingPlaceMediatorSDKOptions options,
    MeetingPlaceMediatorSDKLogger? logger,
  })  : _options = options,
        _logger = logger ??
            DefaultMeetingPlaceMediatorSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'MediatorService';

  final SendMessageQueue sendMessageQueue = SendMessageQueue();
  final DidResolver didResolver;

  final MeetingPlaceMediatorSDKOptions _options;
  final MeetingPlaceMediatorSDKLogger _logger;

  MediatorStreamSubscription? stream;

  Future<MediatorClient> _initMediatorClient({
    required DidManager didManager,
    required String mediatorDid,
    required SignatureScheme signatureScheme,
    bool reauthenticate = false,
  }) async {
    final methodName = '_initMediatorClient';
    final didDocument = await didManager.getDidDocument();

    _logger.info(
      '''Initializing mediator client for DID ${didDocument.id.topAndTail()} and mediator DID ${mediatorDid.topAndTail()}''',
      name: methodName,
    );

    return _retry(
      () async {
        final mediatorDidDocument = await didResolver.resolveDid(mediatorDid);
        final authenticationKeyId = didDocument.authentication.first.id;

        final keyAgreementKeyId = didDocument.matchKeysInKeyAgreement(
            otherDidDocuments: [mediatorDidDocument]).first;

        final client = MediatorClient(
          mediatorDidDocument: mediatorDidDocument,
          keyPair: await didManager.getKeyPairByDidKeyId(keyAgreementKeyId),
          didKeyId: keyAgreementKeyId,
          signer: await didManager.getSigner(authenticationKeyId),
          forwardMessageOptions: const ForwardMessageOptions(
            shouldSign: true,
            shouldEncrypt: true,
            keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
            encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
          ),
          webSocketOptions: WebSocketOptions(
            deleteOnReceive: false,
            pingIntervalInSeconds: _options.websocketPingInterval,
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
          authorizationProvider: await AffinidiAuthorizationProvider.init(
            mediatorDidDocument: mediatorDidDocument,
            didManager: didManager,
          ),
        );

        _logger.info(
          'Mediator client initialized for DID ${didDocument.id} and mediator DID ${mediatorDid.topAndTail()}',
          name: methodName,
        );

        return client;
      },
    );
  }

  Future<MediatorClient> authenticateWithDid({
    required DidManager didManager,
    required String mediatorDid,
    bool reauthenticate = false,
  }) async {
    try {
      return await _initMediatorClient(
        didManager: didManager,
        mediatorDid: mediatorDid,
        signatureScheme: _options.signatureScheme,
        reauthenticate: reauthenticate,
      );
    } catch (e, stackTrace) {
      _logger.error(
        '''Failed to initialize mediator client for mediator DID: ${mediatorDid.topAndTail()}''',
        error: e,
        stackTrace: stackTrace,
        name: 'authenticateWithDid',
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
    final mediatorClient = await authenticateWithDid(
      didManager: didManager,
      mediatorDid: mediatorDid,
    );

    final didDoc = await didManager.getDidDocument();
    final message = OobInvitationMessage.create(from: didDoc.id);

    _logger.info('Completed creating OOB invitation', name: methodName);
    return mediatorClient.createOob(message);
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
      final mediatorClient = await authenticateWithDid(
        didManager: senderDidManager,
        mediatorDid: mediatorDid,
      );

      final encryptedMessage = await signAndEncryptMessage(
        message,
        senderDidManager: senderDidManager,
        recipientDidDocument: recipientDidDocument,
      );

      final senderDidDocument = await senderDidManager.getDidDocument();
      _logger.info(
        'Sending message ${message.type.toString()} from ${senderDidDocument.id.topAndTail()} to ${next.topAndTail()}. Forwarding via ${mediatorClient.mediatorDidDocument.id.topAndTail()}',
        name: methodName,
      );

      await _retry(
        () async {
          await mediatorClient.sendMessage(ForwardMessageBuilder.build(
            encryptedMessage,
            senderDidDocument: senderDidDocument,
            mediatorClient: mediatorClient,
            next: next,
            ephemeral: ephemeral,
            forwardExpiryInSeconds: forwardExpiryInSeconds,
          ));
        },
      );

      _logger.info(
        'Message ${message.type.toString()} with ${message.id} sent from ${senderDidDocument.id.topAndTail()} to ${next.topAndTail()}. Forwarding via ${mediatorClient.mediatorDidDocument.id.topAndTail()}',
        name: methodName,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to send message ${message.type.toString()} with ${message.id} from ${message.from?.topAndTail()} to ${next.topAndTail()}',
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
      final senderDidDocument = await senderDidManager.getDidDocument();
      final client = await authenticateWithDid(
        didManager: senderDidManager,
        mediatorDid: mediatorDid,
      );

      _logger.info(
        'Queuing message from ${senderDidDocument.id.topAndTail()} to ${next.topAndTail()}. Forwarding via ${client.mediatorDidDocument.id.topAndTail()}',
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
        'Message queued from ${senderDidDocument.id.topAndTail()} to ${next.topAndTail()}. Forwarding via ${client.mediatorDidDocument.id.topAndTail()}',
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

  Future<MediatorStreamSubscription> createStreamSubscription({
    required DidManager didManager,
    required String mediatorDid,
    required Duration? deleteMessageDelay,
    bool reauthenticate = false,
    List<MessageWrappingType> messageWrappingTypes = const [
      MessageWrappingType.authcryptSignPlaintext,
    ],
  }) async {
    final methodName = 'subscribe';
    _logger.info('Started subscribing to websocket', name: methodName);

    try {
      final client = await authenticateWithDid(
        didManager: didManager,
        mediatorDid: mediatorDid,
        reauthenticate: reauthenticate,
      );

      final streamSubscription = MediatorStreamSubscription(
        client: client,
        didManager: didManager,
        messageWrappingTypes: messageWrappingTypes,
        deleteMessageDelay: deleteMessageDelay,
        logger: _logger,
      );

      await streamSubscription.initialize();

      _logger.info('Subscribed to mediator: ${mediatorDid.topAndTail()}',
          name: methodName);

      return streamSubscription;
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
      final client = await authenticateWithDid(
        didManager: ownerDidManager,
        mediatorDid: mediatorDid,
      );

      final ownerDidDocument = await ownerDidManager.getDidDocument();

      await _retry(
        () async {
          await client.sendAclManagementMessage(
            AclManagement(
              from: ownerDidDocument.id,
              to: [client.mediatorDidDocument.id],
              body: acl,
            ),
          );
        },
      );

      _logger.info(
        'Updated ACL for owner ${ownerDidDocument.id.topAndTail()} on resource ${mediatorDid.topAndTail()}',
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

  // TODO: improve performance by using streams
  Future<List<FetchMessageResult>> fetch({
    required DidManager didManager,
    required String mediatorDid,
    List<FetchMessageResult>? messages,
    bool deleteOnRetrieve = false,
    DateTime? startFrom,
    int? fetchMessagesBatchSize,
    int? maxResults,
    List<MessageWrappingType> expectedMessageWrappingTypes = const [
      MessageWrappingType.authcryptSignPlaintext,
    ],
  }) async {
    final methodName = 'fetch';
    _logger.info('Fetch messages', name: methodName);

    final client = await authenticateWithDid(
      didManager: didManager,
      mediatorDid: mediatorDid,
    );

    final useBatchSize = fetchMessagesBatchSize ?? 100;

    final messagesList = messages ?? [];
    final mediatorMessages = await _fetchMediatorMessages(
      client: client,
      messages: [],
      deleteOnRetrieve: deleteOnRetrieve,
      startFrom: startFrom,
      fetchMessagesBatchSize: useBatchSize,
      maxResults: maxResults,
    );

    final decryptedMessages = await Future.wait(
      mediatorMessages.map((mediatorMessage) async {
        try {
          final result = await FetchMessageResult.fromMessage(
            mediatorMessage,
            didManager: didManager,
            expectedMessageWrappingTypes: expectedMessageWrappingTypes,
          );

          final messageCreatedTime = result.message?.createdTime;

          if (messageCreatedTime != null) {
            startFrom = startFrom == null
                ? messageCreatedTime.toUtc()
                : (messageCreatedTime.toUtc().isAfter(startFrom!.toUtc())
                    ? messageCreatedTime.toUtc()
                    : startFrom);
          }

          _logger.info(
            '''Process message of type ${result.message?.type.toString()} from ${client.mediatorDidDocument.id.topAndTail()}''',
            name: methodName,
          );

          return result;
        } on UnpackMessageException catch (e, stackTrace) {
          _logger.error(
            'Failed to unpack message from ${client.mediatorDidDocument.id.topAndTail()}',
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

    messagesList.addAll(decryptedMessages);

    if (mediatorMessages.length < useBatchSize ||
        (maxResults != null && mediatorMessages.length >= maxResults)) {
      return messagesList;
    }

    return fetch(
      didManager: didManager,
      mediatorDid: mediatorDid,
      messages: messagesList,
      deleteOnRetrieve: deleteOnRetrieve,
      fetchMessagesBatchSize: fetchMessagesBatchSize,
      maxResults: maxResults,
      startFrom: _findLatestTimestamp(decryptedMessages, startFrom),
    );
  }

  DateTime? _findLatestTimestamp(
    List<FetchMessageResult> messages,
    DateTime? startFrom,
  ) {
    DateTime? nextStartFrom = startFrom;

    for (final result in messages) {
      final messageCreatedTime = result.message?.createdTime;

      if (messageCreatedTime != null) {
        final utcTime = messageCreatedTime.toUtc();

        if (nextStartFrom == null) {
          nextStartFrom = utcTime;
        } else if (utcTime.isAfter(nextStartFrom)) {
          nextStartFrom = utcTime;
        }
      }
    }

    if (nextStartFrom != null) {
      nextStartFrom = nextStartFrom.add(const Duration(microseconds: 1));
    }

    return nextStartFrom;
  }

  Future<List<Map<String, dynamic>>> _fetchMediatorMessages({
    required MediatorClient client,
    required List<Map<String, dynamic>> messages,
    required int fetchMessagesBatchSize,
    bool deleteOnRetrieve = false,
    DateTime? startFrom,
    int? maxResults,
  }) async {
    return _retry(
      () async {
        return await client.fetchMessages(
          deleteOnMediator: deleteOnRetrieve,
          batchSize: fetchMessagesBatchSize,
          startFrom: startFrom,
        );
      },
    );
  }

  Future<void> delete({
    required DidManager didManager,
    required String mediatorDid,
    required List<String> messageHashes,
  }) async {
    final methodName = 'delete';
    _logger.info('Started deleting messages', name: methodName);
    final client = await authenticateWithDid(
      didManager: didManager,
      mediatorDid: mediatorDid,
    );

    await _retry(
      () async {
        await client.deleteMessages(messageIds: messageHashes);
      },
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

      final mediatorDid = await _retry(
        () async {
          final response = await dio.get(
            '$mediatorEndpoint/.well-known/did',
            options: Options(headers: {'CONTENT-TYPE': 'application/json'}),
          );

          return response.data['data'] as String;
        },
      );

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

  String _cacheKey({required String mediatorDid, required String did}) {
    return '$mediatorDid$did';
  }

  /// Helper method to execute operations with retry logic and consistent error handling
  Future<T> _retry<T>(Future<T> Function() operation) async {
    return retry(
      operation,
      retryIf: (e) => ErrorHandlerUtils.isRetryableError(e),
      onRetry: (e) =>
          _logger.warning('Retry attempt due to: $e', name: '_retry'),
      maxDelay: _options.maxRetriesDelay,
      maxAttempts: _options.maxRetries,
    );
  }
}
