import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:ssi/ssi.dart';

import '../../loggers/meeting_place_core_sdk_logger.dart';
import '../../repository/key_repository.dart';
import 'fetch_messages_options.dart';
import 'mediator_message.dart';
import 'mediator_stream_subscription_wrapper.dart';

class MediatorService {
  MediatorService({
    required MeetingPlaceMediatorSDK mediatorSDK,
    required KeyRepository keyRepository,
    required MeetingPlaceCoreSDKLogger logger,
  })  : _mediatorSDK = mediatorSDK,
        _keyRepository = keyRepository,
        _logger = logger;

  final MeetingPlaceMediatorSDK _mediatorSDK;
  final KeyRepository _keyRepository;
  final MeetingPlaceCoreSDKLogger _logger;

  Future<List<MediatorMessage>> fetchMessages({
    required DidManager didManager,
    required String mediatorDid,
    FetchMessagesOptions options = const FetchMessagesOptions(),
  }) async {
    final results = await _mediatorSDK.fetchMessages(
      didManager: didManager,
      mediatorDid: mediatorDid,
      startFrom: options.startFrom,
      fetchMessagesBatchSize: options.batchSize,
      deleteOnRetrieve: options.deleteOnRetrieve,
      deleteFailedMessages: options.deleteFailedMessages,
    );

    final mediatorMessages = await Future.wait(
      results.map((result) async {
        return MediatorMessage.fromPlainTextMessage(
          result.message!,
          keyRepository: _keyRepository,
          messageHash: result.messageHash,
        );
      }).toList(),
    );

    if (options.filterByMessageTypes.isEmpty) {
      return mediatorMessages;
    }

    return mediatorMessages
        .where((m) => options.filterByMessageTypes
            .contains(m.plainTextMessage.type.toString()))
        .toList();
  }

  Future<MediatorStreamSubscriptionWrapper> subscribe({
    required DidManager didManager,
    required String mediatorDid,
  }) async {
    final streamSubscription = await _mediatorSDK
        .subscribeToMessages(didManager, mediatorDid: mediatorDid);

    return MediatorStreamSubscriptionWrapper(
      baseSubscription: streamSubscription,
      keyRepository: _keyRepository,
      logger: _logger,
    );
  }

  Future<void> deletedMessages({
    required DidManager didManager,
    required List<String> messageHashes,
    required String mediatorDid,
  }) {
    // TODO: queue deletion
    return _mediatorSDK.deletedMessages(
      didManager: didManager,
      messageHashes: messageHashes,
      mediatorDid: mediatorDid,
    );
  }

  Future<void> sendMessage(
    PlainTextMessage message, {
    required DidManager senderDidManager,
    required DidDocument recipientDidDocument,
    required String mediatorDid,
    String? next,
    bool? ephemeral,
    int? forwardExpiryInSeconds,
  }) {
    return _mediatorSDK.sendMessage(
      message,
      senderDidManager: senderDidManager,
      recipientDidDocument: recipientDidDocument,
      mediatorDid: mediatorDid,
      next: next,
      ephemeral: ephemeral ?? false,
      forwardExpiryInSeconds: forwardExpiryInSeconds,
    );
  }

  Future<void> updateAcl({
    required DidManager ownerDidManager,
    required AclBody acl,
    required String mediatorDid,
  }) {
    return _mediatorSDK.updateAcl(
      ownerDidManager: ownerDidManager,
      acl: acl,
      mediatorDid: mediatorDid,
    );
  }
}
