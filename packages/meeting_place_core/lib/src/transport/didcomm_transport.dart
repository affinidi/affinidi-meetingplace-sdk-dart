import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    show Device;
import 'package:meeting_place_mediator/meeting_place_mediator.dart'
    show
        MediatorStreamProcessingResult,
        MediatorStreamSubscriptionOptions,
        MeetingPlaceMediatorSDK;
import 'package:ssi/ssi.dart';

import '../sdk/results/register_for_didcomm_notifications_result.dart';
import '../sdk/sdk_error_handler.dart';
import '../service/core_sdk_stream_subscription.dart';
import '../service/group.dart';
import '../service/mediator/fetch_messages_options.dart';
import '../service/mediator/mediator_message.dart';
import '../service/mediator/mediator_service.dart';
import '../service/message/message_service.dart';
import '../service/notification_service/notification_service.dart';

class DIDCommTransport {
  DIDCommTransport({
    required MeetingPlaceMediatorSDK mediatorSDK,
    required MessageService messageService,
    required MediatorService mediatorService,
    required GroupService groupService,
    required NotificationService notificationService,
    required DidResolver didResolver,
    required SDKErrorHandler errorHandler,
    required Wallet wallet,
    required String controlPlaneDid,
    required Future<DidManager> Function(String did) getDidManager,
    required String defaultMediatorDid,
    required List<MessageWrappingType> expectedMessageWrappingTypes,
    required void Function(Device device) onDeviceRegistered,
  }) : _mediatorSDK = mediatorSDK,
       _messageService = messageService,
       _mediatorService = mediatorService,
       _groupService = groupService,
       _notificationService = notificationService,
       _didResolver = didResolver,
       _errorHandler = errorHandler,
       _wallet = wallet,
       _controlPlaneDid = controlPlaneDid,
       _getDidManager = getDidManager,
       _defaultMediatorDid = defaultMediatorDid,
       _expectedMessageWrappingTypes = expectedMessageWrappingTypes,
       _onDeviceRegistered = onDeviceRegistered;

  final MeetingPlaceMediatorSDK _mediatorSDK;
  final MessageService _messageService;
  final MediatorService _mediatorService;
  final GroupService _groupService;
  final NotificationService _notificationService;
  final DidResolver _didResolver;
  final SDKErrorHandler _errorHandler;
  final Wallet _wallet;
  final String _controlPlaneDid;
  final Future<DidManager> Function(String did) _getDidManager;
  String _defaultMediatorDid;
  final List<MessageWrappingType> _expectedMessageWrappingTypes;
  final void Function(Device device) _onDeviceRegistered;

  set defaultMediatorDid(String value) => _defaultMediatorDid = value;

  MeetingPlaceMediatorSDK get mediator => _mediatorSDK;

  Future<void> sendMessage(
    PlainTextMessage message, {
    required String senderDid,
    required String recipientDid,
    String? mediatorDid,
    String? notifyChannelType,
    bool? ephemeral,
    int? forwardExpiryInSeconds,
  }) {
    return _errorHandler.handleError(() async {
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
    });
  }

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
        message,
        senderDidManager: senderDidManager,
        recipientDidDocument: recipientDidDocument,
        mediatorDid: mediatorDid,
        ephemeral: ephemeral,
        forwardExpiryInSeconds: forwardExpiryInSeconds,
      );
    });
  }

  Future<void> sendGroupMessage(
    PlainTextMessage message, {
    required String senderDid,
    required String recipientDid,
    required bool increaseSequenceNumber,
    bool notify = true,
    bool ephemeral = false,
    int? forwardExpiryInSeconds,
  }) {
    return _errorHandler.handleError(() async {
      final senderDidManager = await _getDidManager(senderDid);
      final recipientDidDocument = await _didResolver.resolveDid(recipientDid);
      return _groupService.sendMessage(
        message,
        senderDid: senderDidManager,
        groupDidDocument: recipientDidDocument,
        increaseSequenceNumber: increaseSequenceNumber,
        notify: notify,
        ephemeral: ephemeral,
        forwardExpiryInSeconds: forwardExpiryInSeconds,
      );
    });
  }

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

  Future<
    CoreSDKStreamSubscription<MediatorMessage, MediatorStreamProcessingResult>
  >
  subscribe(
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

  Future<RegisterForDidcommNotificationsResult> registerForNotifications({
    String? mediatorDid,
    String? recipientDid,
  }) {
    return _errorHandler.handleError(() async {
      final result = await _notificationService.registerForDIDCommNotifications(
        wallet: _wallet,
        controlPlaneDid: _controlPlaneDid,
        recipientDid: recipientDid,
        mediatorDid: mediatorDid ?? _defaultMediatorDid,
      );
      _onDeviceRegistered(result.device);
      return RegisterForDidcommNotificationsResult(
        recipientDid: result.recipientDid,
        device: result.device,
      );
    });
  }
}
