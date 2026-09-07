import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart'
    show
        MediatorMessageRequest,
        MediatorStreamProcessingResult,
        MediatorStreamSubscriptionOptions,
        MeetingPlaceMediatorSDK;
import 'package:ssi/ssi.dart';

import '../sdk/sdk_error_handler.dart';
import '../service/core_sdk_stream_subscription.dart';
import '../service/mediator/fetch_messages_options.dart';
import '../service/mediator/mediator_message.dart';
import '../service/mediator/mediator_service.dart';
import '../service/message/message_service.dart';

/// DIDComm-specific messaging operations that don't have a channel-level
/// analogue on `MeetingPlaceTransport` and so aren't exposed through it.
///
/// This includes mediator-specific concerns such as queueing/fetching
/// messages and subscribing to a mediator stream.
class DIDCommTransport {
  /// Creates a [DIDCommTransport].
  DIDCommTransport({
    required MeetingPlaceMediatorSDK mediatorSDK,
    required MessageService messageService,
    required MediatorService mediatorService,
    required DidResolver didResolver,
    required SDKErrorHandler errorHandler,
    required Future<DidManager> Function(String did) getDidManager,
    required String defaultMediatorDid,
    required List<MessageWrappingType> expectedMessageWrappingTypes,
  }) : _mediatorSDK = mediatorSDK,
       _messageService = messageService,
       _mediatorService = mediatorService,
       _didResolver = didResolver,
       _errorHandler = errorHandler,
       _getDidManager = getDidManager,
       _defaultMediatorDid = defaultMediatorDid,
       _expectedMessageWrappingTypes = expectedMessageWrappingTypes;

  final MeetingPlaceMediatorSDK _mediatorSDK;
  final MessageService _messageService;
  final MediatorService _mediatorService;
  final DidResolver _didResolver;
  final SDKErrorHandler _errorHandler;
  final Future<DidManager> Function(String did) _getDidManager;
  String _defaultMediatorDid;
  final List<MessageWrappingType> _expectedMessageWrappingTypes;

  /// Updates the mediator DID used by default when a call doesn't specify
  /// one explicitly.
  set defaultMediatorDid(String value) => _defaultMediatorDid = value;

  /// The underlying mediator SDK instance.
  MeetingPlaceMediatorSDK get mediator => _mediatorSDK;

  /// Sends [message] directly to [recipientDid] via the mediator.
  Future<void> sendMessage(
    PlainTextMessage message, {
    required String senderDid,
    required String recipientDid,
    String? mediatorDid,
    String? notifyChannelType,
    bool? ephemeral,
    int? forwardExpiryInSeconds,
  }) async {
    final senderDidManager = await _getDidManager(senderDid);
    return _messageService.sendMessage(
      message,
      senderDidManager: senderDidManager,
      recipientDid: recipientDid,
      mediatorDid: mediatorDid ?? _defaultMediatorDid,
      notifyChannelType: notifyChannelType,
      ephemeral: ephemeral ?? false,
      forwardExpiryInSeconds: forwardExpiryInSeconds,
    );
  }

  /// Queues [message] with the mediator for later delivery to [recipientDid].
  Future<void> queueMessage(
    PlainTextMessage message, {
    required String senderDid,
    required String recipientDid,
    String? mediatorDid,
    bool? ephemeral,
    int? forwardExpiryInSeconds,
  }) {
    return _errorHandler.handleError(() async {
      final senderDidManager = await _getDidManager(senderDid);
      final recipientDidDocument = await _didResolver.resolveDid(recipientDid);
      await _mediatorSDK.queueMessage(
        MediatorMessageRequest(
          message: message,
          senderDidManager: senderDidManager,
          recipientDidDocument: recipientDidDocument,
          mediatorDid: mediatorDid,
          ephemeral: ephemeral,
          forwardExpiryInSeconds: forwardExpiryInSeconds,
        ),
      );
    });
  }

  /// Fetches queued messages for [did] from the mediator.
  Future<List<MediatorMessage>> fetchMessages({
    required String did,
    String? mediatorDid,
    bool deleteOnRetrieve = false,
    bool deleteFailedMessages = false,
  }) {
    return _errorHandler.handleError(() async {
      final didManager = await _getDidManager(did);
      return _mediatorService.fetchMessages(
        didManager: didManager,
        mediatorDid: mediatorDid ?? _defaultMediatorDid,
        options: FetchMessagesOptions(
          deleteFailedMessages: deleteFailedMessages,
          deleteOnRetrieve: deleteOnRetrieve,
          expectedMessageWrappingTypes: _expectedMessageWrappingTypes,
        ),
      );
    });
  }

  /// Deletes the messages identified by [messageHashes] from the mediator.
  Future<void> deleteMessages({
    required String did,
    String? mediatorDid,
    required List<String> messageHashes,
  }) {
    return _errorHandler.handleError(() async {
      final didManager = await _getDidManager(did);
      return _mediatorService.deleteMessages(
        didManager: didManager,
        mediatorDid: mediatorDid ?? _defaultMediatorDid,
        messageHashes: messageHashes,
      );
    });
  }

  /// Subscribes to the live stream of incoming messages for [did] from the
  /// mediator.
  Future<
    CoreSDKStreamSubscription<MediatorMessage, MediatorStreamProcessingResult>
  >
  subscribeToMediator(
    String did, {
    String? mediatorDid,
    MediatorStreamSubscriptionOptions? options,
  }) {
    return _errorHandler.handleError(() async {
      final didManager = await _getDidManager(did);
      return _mediatorService.subscribe(
        didManager: didManager,
        mediatorDid: mediatorDid ?? _defaultMediatorDid,
        options: MediatorStreamSubscriptionOptions(
          deleteMessageDelay:
              options?.deleteMessageDelay ??
              MediatorStreamSubscriptionOptions.defaults.deleteMessageDelay,
          fetchMessagesOnConnect:
              options?.fetchMessagesOnConnect ??
              MediatorStreamSubscriptionOptions.defaults.fetchMessagesOnConnect,
          expectedMessageWrappingTypes:
              options?.expectedMessageWrappingTypes ??
              _expectedMessageWrappingTypes,
        ),
      );
    });
  }
}
