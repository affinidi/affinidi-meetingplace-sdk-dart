import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:ssi/ssi.dart';

import '../../../meeting_place_core.dart' hide GroupMessage;
import '../group/group_message.dart';
import '../../protocol/message/plaintext_message_extension.dart';
import 'fetch_messages_options.dart';

class MediatorService {
  MediatorService({
    required MediatorSDK mediatorSDK,
    required KeyRepository keyRepository,
    required MeetingPlaceCoreSDKLogger logger,
  })  : _mediatorSDK = mediatorSDK,
        _keyRepository = keyRepository,
        _logger = logger;

  final MediatorSDK _mediatorSDK;
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
        final message = result.message!;
        if (message.isOfType(MeetingPlaceProtocol.groupMessage)) {
          final decryptedMessage = await _handleGroupMessage(message);
          return MediatorMessage(
            plainTextMessage: decryptedMessage,
            messageHash: result.messageHash,
            seqNo: message.body!['seqNo'],
            fromDid: message.body!['fromDid'],
          );
        }

        return MediatorMessage(
          plainTextMessage: message,
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

  Future<MediatorStream> subscribeToMessages({
    required DidManager didManager,
    required String mediatorDid,
    bool deleteOnMediator = false,
  }) async {
    final mediatorChannel = await _mediatorSDK.subscribeToMessages(
      didManager,
      mediatorDid: mediatorDid,
      deleteOnMediator: deleteOnMediator,
    );

    final mpxStream = MediatorStream(
      mediatorChannel: mediatorChannel,
      logger: _logger,
    );
    mediatorChannel.listen((message) async {
      if (message.isOfType(MeetingPlaceProtocol.groupMessage)) {
        final decrypted = await _handleGroupMessage(message);
        return mpxStream.pushData(
          MediatorMessage(
            plainTextMessage: decrypted,
            seqNo: message.body!['seqNo'],
            fromDid: message.body!['fromDid'],
          ),
        );
      }

      mpxStream.pushData(MediatorMessage(plainTextMessage: message));
    });

    return mpxStream;
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

  Future<PlainTextMessage> _handleGroupMessage(PlainTextMessage message) async {
    final keyPair = await _keyRepository.getKeyPair(message.to!.first);
    return GroupMessage.decrypt(
      message,
      privateKeyBytes: keyPair!.privateKeyBytes,
    );
  }
}
