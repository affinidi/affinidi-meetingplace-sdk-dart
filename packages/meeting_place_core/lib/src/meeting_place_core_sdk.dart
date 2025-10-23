import 'dart:async';

import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'constants/sdk_constants.dart';
import 'entity/channel.dart';
import 'entity/group_connection_offer.dart';
import 'event_handler/control_plane_stream_event.dart';
import 'exception/sdk_exception.dart';
import 'loggers/default_mpx_sdk_logger.dart';
import 'loggers/logger_adapter.dart';
import 'loggers/mpx_sdk_logger.dart';
import 'messages/utils.dart';
import 'protocol/protocol.dart';
import 'sdk/connection_offer_type.dart';
import 'meeting_place_core_sdk_options.dart';
import 'sdk/results/accept_oob_flow_result.dart';
import 'sdk/results/create_oob_flow_result.dart';
import 'sdk/results/register_for_didcomm_notifications_result.dart';
import 'service/connection_manager/connection_manager.dart';
import 'repository/repository_config.dart';
import 'service/connection_offer/connection_offer_service.dart';
import 'service/mediator/fetch_messages_options.dart';
import 'service/mediator/mediator_message.dart';
import 'service/mediator/mediator_service.dart';
import 'service/notification_service/notification_service.dart';
import 'service/outreach/outreach_service.dart';
import 'service/mediator/mediator_stream.dart';
import 'service/oob/oob_stream.dart';
import 'service/oob/oob_stream_data.dart';
import 'utils/cached_did_resolver.dart';
import 'package:ssi/ssi.dart';

import 'service/connection_service.dart';
import 'entity/connection_offer.dart';
import 'entity/group.dart';
import 'event_handler/control_plane_event_handler_manager.dart';
import 'event_handler/control_plane_event_stream_manager.dart';
import 'meeting_place_core_sdk_exception.dart';
import 'sdk/sdk.dart' as sdk;
import 'service/control_plane_event_service.dart';
import 'service/group.dart';

/// # Core SDK
/// The Affinidi Meeting Place - Core SDK provides a high-level interface for coordinating connection setup using the discovery control plane API and mediator. This SDK acts as an orchestrator, applying business logic on top of underlying APIs to simplify integration.
/// ## Discovery Event Stream
/// The DiscoveryEventStream exposes a stream that can be listened to, pushing each event after applying business logic within the SDK. The processEventStream method triggers this process, using a debounce mechanism to call the API at most once every second. This ensures efficient processing and keeps the main isolate available for background tasks.
/// To improve performance and responsiveness, the event stream processing runs in a separate Dart isolate.
/// ## Device
/// The Device object is used be provided once and reused throughout the entire flow. If it changes, you can easily update it without affecting other parts of your application.
/// ## Error Handling
/// All methods within this SDK throw a unified MeetingPlaceCoreSDKException, which includes:
/// * A message providing context about the error
/// * A code that can be used to map specific error messages based on consumer requirements
/// * A stacktrace for identifying the root cause of the issue
/// By using a consistent exception type, you can easily handle and respond to errors in your application.
///
/// Example:
/// ```dart
/// final wallet = PersistentWallet(InMemoryKeyStore())
/// final storage = InMemoryStorage();
/// final repositoryConfig = RepositoryConfig(
///   connectionOfferRepository: ConnectionOfferRepositoryImpl(storage: storage),
///   groupRepository: GroupRepositoryImpl(storage: storage),
///   channelRepository: ChannelRepositoryImpl(storage: storage),
///   keyRepository: KeyRepositoryImpl(storage: storage),
/// );
///
/// final sdk = MeetingPlaceCoreSDK.create(
///   wallet: wallet,
///   repositoryConfig: repositoryConfig,
///   mediatorDid: '<YOUR-MEDIATOR-DID:.well-known>',
///   controlPlaneDid: '<YOUR-CONTROL-PLANE-DID>',
/// );
/// ```
///
/// Wallet Compatibility Notice:
/// Depending on the discovery API version, you can use any wallet
/// implementation. However, there is one limitation: when using the
/// Affinidi-hosted version of the API, you must use the `PersistentWallet`
/// with `p256` keys. This restriction is temporary and will be lifted in the
/// coming weeks as we transition to a new server-side wallet implementation
/// replacing the current KMS-based solution.
class MeetingPlaceCoreSDK {
  /// Creates an instance of [MeetingPlaceCoreSDK].
  ///
  /// This constructor requires all of its dependencies to be provided via
  /// **named parameters**. Some parameters are directly assigned to public
  /// fields, while others are assigned to private fields via the initializer list.
  ///
  /// ### Parameters
  /// - `wallet` (`Wallet`): The wallet instance used for cryptographic operations.
  /// - `repositoryConfig` (`RepositoryConfig`): Configuration for repository storage.
  /// - `controlPlaneDid` (`String`): The DID (Decentralized Identifier) of this service.
  /// - `mediatorSDK` (`MediatorSDK`): Instance of the mediator SDK used for routing messages.
  /// - `controlPlaneSDK` (`ControlPlaneSDK`): Instance of the control plane SDK for discovering other agents.
  /// - `connectionManager` (`ConnectionManager`): Manages connections between agents.
  /// - `connectionService` (`ConnectionService`): Service that handles connection protocols.
  /// - `discoveryEventService` (`DiscoveryEventService`): Service that handles discovery events.
  /// - `discoveryEventStreamManager` (`DiscoveryEventStreamManager`): Manages streaming of discovery events.
  /// - `groupService` (`GroupService`): Handles group-related operations.
  /// - `outreachService` (`OutreachService`): Handles outreach notifications
  /// - `didResolver` (`DidResolver`): Resolves DIDs to their corresponding DID Documents.
  /// - `mediatorDid` (`String`): The DID of the mediator agent.
  ///
  /// ### Notes
  /// - Parameters marked as `required` must be provided when creating an instance.
  /// - The initializer list (`: _repositoryConfig = repositoryConfig, ...`) is used
  ///   to assign values to private fields that cannot be assigned directly using `this`.
  MeetingPlaceCoreSDK._({
    required this.wallet,
    required RepositoryConfig repositoryConfig,
    required String controlPlaneDid,
    required MeetingPlaceMediatorSDK mediatorSDK,
    required ControlPlaneSDK controlPlaneSDK,
    required ConnectionManager connectionManager,
    required ConnectionService connectionService,
    required ControlPlaneEventService controlPlaneEventService,
    required ControlPlaneEventStreamManager controlPlaneEventStreamManager,
    required GroupService groupService,
    required NotificationService notificationService,
    required OutreachService outreachService,
    required MediatorService mediatorService,
    required DidResolver didResolver,
    required String mediatorDid,
    required MeetingPlaceCoreSDKOptions options,
    required MeetingPlaceCoreSDKLogger logger,
  })  : _repositoryConfig = repositoryConfig,
        _controlPlaneDid = controlPlaneDid,
        _mediatorSDK = mediatorSDK,
        _controlPlaneSDK = controlPlaneSDK,
        _connectionManager = connectionManager,
        _connectionService = connectionService,
        _controlPlaneEventService = controlPlaneEventService,
        _controlPlaneEventStreamManager = controlPlaneEventStreamManager,
        _groupService = groupService,
        _notificationService = notificationService,
        _outreachService = outreachService,
        _mediatorService = mediatorService,
        _didResolver = didResolver,
        _mediatorDid = mediatorDid,
        _options = options,
        _logger = logger;

  final Wallet wallet;
  final RepositoryConfig _repositoryConfig;
  final String _controlPlaneDid;
  final MeetingPlaceMediatorSDK _mediatorSDK;
  final ControlPlaneSDK _controlPlaneSDK;
  final ConnectionManager _connectionManager;
  final ConnectionService _connectionService;
  final ControlPlaneEventService _controlPlaneEventService;
  final ControlPlaneEventStreamManager _controlPlaneEventStreamManager;
  final GroupService _groupService;
  final NotificationService _notificationService;
  final MediatorService _mediatorService;
  final OutreachService _outreachService;
  final DidResolver _didResolver;
  final MeetingPlaceCoreSDKOptions _options;
  final MeetingPlaceCoreSDKLogger _logger;

  String _mediatorDid;

  static const String _className = 'MeetingPlaceCoreSDK';

  /// A static method that creates an instance of [MeetingPlaceCoreSDK].
  ///
  /// **Parameters:**
  /// - [wallet]: A digital wallet to manage cryptographic keys supporting
  /// different algorithms for signing and verifying VC and VP.
  /// - [repositoryConfig]: A repository object which defines the storage,
  /// group, key and channel repository objects.
  /// - [mediatorDid]: The mediator DID.
  /// - [controlPlaneDid]: The control plane DID.
  /// - [options]: Instance of [MeetingPlaceCoreSDKOptions]
  ///
  /// **Returns:**
  /// - [MeetingPlaceCoreSDK] instance with all the required instance parameters.
  static Future<MeetingPlaceCoreSDK> create({
    required Wallet wallet,
    required RepositoryConfig repositoryConfig,
    required String mediatorDid,
    required String controlPlaneDid,
    MeetingPlaceCoreSDKOptions options = const MeetingPlaceCoreSDKOptions(),
    MeetingPlaceCoreSDKLogger? logger,
  }) async {
    final methodName = 'create';
    final mpxLogger = LoggerAdapter(
      className: _className,
      sdkName: coreSDKName,
      logger: logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className),
    );

    mpxLogger.info('Starting Core SDK initialization', name: methodName);

    final controlPlaneLogger = LoggerAdapter(
      className: ControlPlaneSDK.className,
      sdkName: controlPlaneSDKName,
      logger: logger,
    );

    final mediatorLogger = LoggerAdapter(
      className: MeetingPlaceMediatorSDK.className,
      sdkName: mediatorSDKName,
      logger: logger,
    );

    final didResolver = CachedDidResolver(
      resolverAddress: options.didResolverAddress,
    );

    final offerService = ConnectionOfferService(
      connectionOfferRepository: repositoryConfig.connectionOfferRepository,
      channelRepository: repositoryConfig.channelRepository,
    );

    final connectionManager = ConnectionManager(
      keyRepository: repositoryConfig.keyRepository,
      logger: mpxLogger,
    );

    final didManager = await connectionManager.generateRootDid(wallet);
    final controlPlaneSDK = ControlPlaneSDK(
      didManager: didManager,
      controlPlaneDid: controlPlaneDid,
      mediatorDid: mediatorDid,
      didResolver: didResolver,
      controlPlaneSDKConfig: ControlPlaneSDKOptions(
        maxRetries: options.maxRetries,
        maxRetriesDelay: options.maxRetriesDelay,
        connectTimeout: options.connectTimeout,
        receiveTimeout: options.receiveTimeout,
      ),
      logger: controlPlaneLogger,
    );

    final mediatorSDK = MeetingPlaceMediatorSDK(
      mediatorDid: mediatorDid,
      didResolver: didResolver,
      logger: mediatorLogger,
    );

    final connectionService = ConnectionService(
      connectionOfferRepository: repositoryConfig.connectionOfferRepository,
      channelRepository: repositoryConfig.channelRepository,
      connectionManager: connectionManager,
      controlPlaneSDK: controlPlaneSDK,
      mediatorSDK: mediatorSDK,
      offerService: offerService,
      didResolver: didResolver,
      logger: mpxLogger,
    );

    final discoveryEventStreamManager = ControlPlaneEventStreamManager(
      logger: mpxLogger,
    );

    final groupService = GroupService(
      wallet: wallet,
      connectionManager: connectionManager,
      connectionOfferRepository: repositoryConfig.connectionOfferRepository,
      connectionService: connectionService,
      groupRepository: repositoryConfig.groupRepository,
      channelRepository: repositoryConfig.channelRepository,
      keyRepository: repositoryConfig.keyRepository,
      controlPlaneSDK: controlPlaneSDK,
      mediatorSDK: mediatorSDK,
      offerService: offerService,
      didResolver: didResolver,
      logger: mpxLogger,
    );

    final mediatorService = MediatorService(
      mediatorSDK: mediatorSDK,
      keyRepository: repositoryConfig.keyRepository,
      logger: mpxLogger,
    );

    final discoveryEventManager = ControlPlaneEventManager(
      wallet: wallet,
      mediatorSDK: mediatorSDK,
      mediatorService: mediatorService,
      controlPlaneSDK: controlPlaneSDK,
      connectionService: connectionService,
      connectionManager: connectionManager,
      connectionOfferRepository: repositoryConfig.connectionOfferRepository,
      groupRepository: repositoryConfig.groupRepository,
      channelRepository: repositoryConfig.channelRepository,
      streamManager: discoveryEventStreamManager,
      didResolver: didResolver,
      logger: mpxLogger,
    );

    // TODO: combine manager and service?
    final discoveryEventService = ControlPlaneEventService(
      controlPlaneSDK: controlPlaneSDK,
      discoveryEventManager: discoveryEventManager,
      logger: mpxLogger,
    );

    final notificationService = NotificationService(
      controlPlaneSDK: controlPlaneSDK,
      mediatorSDK: mediatorSDK,
      connectionManager: connectionManager,
      logger: mpxLogger,
    );

    final outreachService = OutreachService(
      mediatorSDK: mediatorSDK,
      controlPlaneSDK: controlPlaneSDK,
      connectionManager: connectionManager,
      didResolver: didResolver,
    );

    mpxLogger.info('Completed initializing CoreSDK', name: methodName);
    return MeetingPlaceCoreSDK._(
      wallet: wallet,
      repositoryConfig: repositoryConfig,
      controlPlaneDid: controlPlaneDid,
      mediatorSDK: mediatorSDK,
      controlPlaneSDK: controlPlaneSDK,
      connectionManager: connectionManager,
      connectionService: connectionService,
      controlPlaneEventService: discoveryEventService,
      controlPlaneEventStreamManager: discoveryEventStreamManager,
      groupService: groupService,
      notificationService: notificationService,
      mediatorService: mediatorService,
      outreachService: outreachService,
      didResolver: didResolver,
      mediatorDid: mediatorDid,
      options: options,
      logger: mpxLogger,
    );
  }

  /// Returns instance of used low level [MeetingPlaceMediatorSDK].
  MeetingPlaceMediatorSDK get mediator => _mediatorSDK;

  /// Returns instance of used low level [ControlPlaneSDK].
  ControlPlaneSDK get discovery => _controlPlaneSDK;

  /// Returns a stream of [ControlPlaneStreamEvent] events.
  ///
  /// To emit events based on pending notifications from the Control Plane API,
  /// call [processControlPlaneEvents]. Events are first processed internally before
  /// being published to the stream.
  ///
  /// Each emitted event includes its type and the updated [Channel] entity
  /// associated with it.
  Stream<ControlPlaneStreamEvent> get controlPlaneEventsStream {
    return _controlPlaneEventStreamManager.stream;
  }

  /// Updates the default mediator DID used for subsequent method invocations
  /// when no mediator DID is provided explicitly.
  ///
  /// The updated mediator DID is also propagated to the lower-level
  /// [ControlPlaneSDK] and [MeetingPlaceMediatorSDK].
  ///
  /// **Parameters:**
  /// - [mediatorDid] — The new mediator DID to set as the default.
  set mediatorDid(String mediatorDid) {
    _mediatorDid = mediatorDid;
    _controlPlaneSDK.mediatorDid = mediatorDid;
    _mediatorSDK.mediatorDid = mediatorDid;
  }

  /// Updates the [Device] used for subsequent method invocations.
  ///
  /// A [Device] is required by [ControlPlaneSDK] to send push notifications
  /// to the corresponding device.
  ///
  /// **Parameters:**
  /// - [device] — The device instance to use for subsequent method invocations.
  set device(Device device) {
    _controlPlaneSDK.device = device;
  }

  /// Generates a new DID using the provided [Wallet] instance.
  ///
  /// The key store repository is used to track the latest account index, and
  /// the generated [DidManager] instance is stored via the repository’s `save`
  /// method.
  ///
  /// **Returns:**
  /// - A [DidManager] instance
  Future<DidManager> generateDid() async {
    return _connectionManager.generateDid(wallet);
  }

  /// Creates an Out-Of-Band invitation for a User.
  ///
  /// **Parameters:**
  /// - [vCard]: An object that contains information about who is offering the
  ///   offer. This helps others know whom they are connecting with and provides
  ///   necessary contact details.
  ///
  /// - [permanentChannelDid] - If specified, this DID is used as the permanent
  ///   channel DID within the channel entity. If omitted, a new DID will be
  ///   generated automatically.
  ///
  /// - [mediatorDid] - The mediator's DID. If not provided, the SDK will use
  ///   the mediator DID configured in the current instance.
  ///
  /// - [externalRef] - Application-specific data that is passed through to
  ///   internal oob entity and can be referenced later for tracking or
  ///   identification purposes. [externalRef] is accessible on the current
  ///   device only.
  ///
  /// Returns [CreateOobFlowResult]
  Future<CreateOobFlowResult> createOobFlow({
    required VCard vCard,
    String? permanentChannelDid,
    String? mediatorDid,
    String? externalRef,
  }) async {
    final methodName = 'createOobFlow';
    _logger.info('Started creating OOB invitation', name: methodName);

    DidManager didManager;
    if (permanentChannelDid != null) {
      didManager = await _connectionManager.getDidManagerForDid(
        wallet,
        permanentChannelDid,
      );
    } else {
      didManager = await generateDid();
    }

    final didManagerDidDoc = await didManager.getDidDocument();

    await _mediatorSDK.updateAcl(
      ownerDidManager: didManager,
      acl: AclSet.toPublic(ownerDid: didManagerDidDoc.id),
    );

    final oobMessage = OobInvitationMessage.create(from: didManagerDidDoc.id);

    final result = await _controlPlaneSDK.execute(
      CreateOobCommand(oobInvitationMessage: oobMessage),
    );

    final mediatorChannel = await _mediatorSDK.subscribeToMessages(
      didManager,
      mediatorDid: result.mediatorDid,
    );

    final oobStream =
        OobStream(onDispose: () => mediatorChannel.dispose(), logger: _logger);
    _logger.info(
      'Listening for messages on mediator channel',
      name: methodName,
    );

    mediatorChannel.listen((message) async {
      if (message.type.toString() ==
          MeetingPlaceProtocol.connectionSetup.value) {
        final otherPartyVcard = getVCardDataOrEmptyFromAttachments(
          message.attachments,
        );

        final otherPartyPermanentChannelDid = message.body!['channel_did'];
        final permanentChannelDidManager = permanentChannelDid != null
            ? await _connectionManager.getDidManagerForDid(
                wallet,
                permanentChannelDid,
              )
            : await generateDid();
        final permanentChannelDidDoc =
            await permanentChannelDidManager.getDidDocument();

        await _connectionService.sendConnectionRequestApprovalToMediator(
          offerPublishedDid: didManager,
          permanentChannelDid: permanentChannelDidManager,
          otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
          otherPartyAcceptOfferDid: message.from!,
          outboundMessageId: oobMessage.id,
          vCard: vCard,
          mediatorDid: result.mediatorDid,
        );

        final channel = Channel(
          offerLink: oobMessage.id,
          publishOfferDid: didManagerDidDoc.id,
          mediatorDid: result.mediatorDid,
          outboundMessageId: oobMessage.id,
          acceptOfferDid: message.from!,
          permanentChannelDid: permanentChannelDidDoc.id,
          otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
          status: ChannelStatus.inaugaurated,
          type: ChannelType.oob,
          vCard: vCard,
          otherPartyVCard: otherPartyVcard,
          externalRef: externalRef,
        );

        await _repositoryConfig.channelRepository.createChannel(channel);

        _logger.info(
          'OOB invitation accepted, channel created with ID: ${channel.id}',
          name: methodName,
        );

        _controlPlaneEventStreamManager.pushEvent(
          ControlPlaneStreamEvent(
            channel: channel,
            type: ControlPlaneEventType.ChannelActivity,
          ),
        );

        oobStream.pushEvent(
          OobStreamData(
            eventType: EventType.connectionSetup,
            message: message,
            channel: channel,
          ),
        );
      }
    });

    return CreateOobFlowResult(
      stream: oobStream,
      oobUrl: Uri.parse(result.oobUrl),
    );
  }

  /// Accepts an Out-Of-Band invitation created by a User.
  ///
  /// **Parameters:**
  /// - [oobUrl]: The OOB URL.
  ///
  /// - [vCard]: An object that contains information about who is offering the
  ///   offer. This helps others know whom they are connecting with and provides
  ///   necessary contact details.
  ///
  /// - [externalRef] - Application-specific data that is passed through to
  ///   internal oob entity and can be referenced later for tracking or
  ///   identification purposes. [externalRef] is accessible on the current
  ///   device only.
  ///
  /// Returns [AcceptOobFlowResult]
  Future<AcceptOobFlowResult> acceptOobFlow(
    Uri oobUrl, {
    required VCard vCard,
    String? externalRef,
  }) async {
    final methodName = 'acceptOobFlow';
    _logger.info('Started accepting OOB invitation', name: methodName);

    final acceptOfferDid = await generateDid();
    final acceptOfferDidDoc = await acceptOfferDid.getDidDocument();

    final permanentChannelDid = await generateDid();
    final didDoc = await permanentChannelDid.getDidDocument();

    PlainTextMessage invitationMessage;
    String actualMediatorDid = _mediatorDid;

    try {
      _logger.info('Fetching OOB invitation', name: methodName);
      final oobInfo = await _controlPlaneSDK.execute(
        GetOobCommand(oobId: oobUrl.pathSegments.last),
      );

      invitationMessage = OobInvitationMessage.fromBase64(
        oobInfo.invitationMessage,
      );
      actualMediatorDid = oobInfo.mediatorDid;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to fetch OOB invitation:',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      invitationMessage = await _mediatorSDK.getOob(
        oobUrl,
        didManager: acceptOfferDid,
      );
    }

    final channel = Channel(
      offerLink: invitationMessage.id,
      publishOfferDid: invitationMessage.from!,
      mediatorDid: actualMediatorDid,
      status: ChannelStatus.waitingForApproval,
      outboundMessageId: invitationMessage.id,
      acceptOfferDid: acceptOfferDidDoc.id,
      permanentChannelDid: didDoc.id,
      type: ChannelType.oob,
      vCard: vCard,
      externalRef: externalRef,
    );

    final mediatorChannel = await _mediatorSDK.subscribeToMessages(
      acceptOfferDid,
      mediatorDid: actualMediatorDid,
    );

    final oobStream =
        OobStream(onDispose: () => mediatorChannel.dispose(), logger: _logger);

    _logger.info(
      'Listening for messages on mediator channel',
      name: methodName,
    );
    mediatorChannel.listen((message) async {
      if (message.type.toString() ==
              MeetingPlaceProtocol.connectionAccepted.value &&
          message.parentThreadId == invitationMessage.id) {
        final otherPartyPermanentChannelDid = message.body!['channel_did'];

        await _mediatorSDK.updateAcl(
          ownerDidManager: permanentChannelDid,
          acl: AccessListAdd(
            ownerDid: didDoc.id,
            granteeDids: [otherPartyPermanentChannelDid],
          ),
        );

        final otherPartyVCard = getVCardDataOrEmptyFromAttachments(
          message.attachments,
        );

        channel.otherPartyPermanentChannelDid = otherPartyPermanentChannelDid;
        channel.otherPartyVCard = otherPartyVCard;
        channel.status = ChannelStatus.inaugaurated;

        await _repositoryConfig.channelRepository.updateChannel(channel);

        _controlPlaneEventStreamManager.pushEvent(
          ControlPlaneStreamEvent(
            channel: channel,
            type: ControlPlaneEventType.ChannelActivity,
          ),
        );

        oobStream.pushEvent(
          OobStreamData(
            eventType: EventType.connectionAccepted,
            message: message,
            channel: channel,
          ),
        );

        _logger.info(
          'OOB invitation accepted, channel created with ID: ${channel.id}',
          name: methodName,
        );
      }
    });

    await _connectionService.sendAcceptOfferToMediator(
      acceptOfferDid: acceptOfferDid,
      permanentChannelDidDocument: didDoc,
      invitationMessage: invitationMessage,
      mediatorDid: actualMediatorDid,
      acceptVCard: vCard,
    );

    await _repositoryConfig.channelRepository.createChannel(channel);
    return AcceptOobFlowResult(stream: oobStream, channel: channel);
  }

  /// Validates whether a given offer phrase is already in use within the system.
  ///
  /// **Parameters:**
  /// - [phrase] - The offer phrase to be checked for availability.
  ///
  /// **Returns:**
  /// - A [sdk.ValidateOfferPhraseResult] object which provides isAvailable flag that shows whether the offer
  /// phrase is already in use.
  Future<sdk.ValidateOfferPhraseResult> validateOfferPhrase(
    String phrase,
  ) async {
    return _withSdkExceptionHandling(() async {
      final result = await _controlPlaneSDK.execute(
        ValidateOfferPhraseCommand(phrase: phrase.trim()),
      );

      return sdk.ValidateOfferPhraseResult(isAvailable: result.isAvailable);
    });
  }

  /// Registers the device for push notifications using the provided deviceToken
  /// from the OS-native push notification service, which will be used to
  /// notify the device about events in the Meeting Place flow and automatically included
  /// in subsequent API calls.
  ///
  /// **Parameters:**
  /// - [deviceToken] - The device token obtained from the operating system's
  /// native push notification service.
  ///
  /// **Returns:**
  /// - A [Device] instance used for subsequent SDK calls.

  Future<Device> registerForPushNotifications(String deviceToken) async {
    return _withSdkExceptionHandling(() async {
      final device = await _notificationService.registerForPushNotifications(
        deviceToken,
      );

      _controlPlaneSDK.device = device;
      return device;
    });
  }

  /// Registers the device for DIDComm notifications using a combination of the
  /// recipient's DID and the mediator's DID as a unique device token. This
  /// token identifies the recipient and enables message retrieval or
  /// subscription to the mediator.
  ///
  /// Once registered, the DID can be used to fetch messages or subscribe to
  /// updates from the mediator.
  ///
  /// The SDK updates the ACL for the newly created recipient DID to allow
  /// receiving messages from the mediator identified by the given
  /// [mediatorDid].
  ///
  /// [mediatorDid] - The mediator's DID. If not provided, the SDK will use the
  /// mediator DID configured in the current instance.
  ///
  /// **Returns:**
  /// - A [RegisterForDidcommNotificationsResult] containing the Device used
  /// for subsequent SDK calls and the generated DidManager for the recipient
  /// DID.

  Future<RegisterForDidcommNotificationsResult>
      registerForDIDCommNotifications({
    String? mediatorDid,
    String? recipientDid,
  }) async {
    return _withSdkExceptionHandling(() async {
      final result = await _notificationService.registerForDIDCommNotifications(
        wallet: wallet,
        controlPlaneDid: _controlPlaneDid,
        recipientDid: recipientDid,
        mediatorDid: mediatorDid ?? _mediatorDid,
      );

      _controlPlaneSDK.device = result.device;
      return RegisterForDidcommNotificationsResult(
        recipientDid: result.recipientDid,
        device: result.device,
      );
    });
  }

  /// Publishes an offer that others can discover. It's accessible for other
  /// users or systems to find and connect.
  ///
  /// **Parameters:**
  /// - [offerName] - The name of your offer as it will be displayed when others
  /// search for offers.
  ///
  /// [type] - Type of the offer. Either invitation, outreachInvitation
  ///   or groupInvitation.
  ///
  /// - [vCard] - A VCard that contains information about who is offering the
  /// offer. This helps others know whom they are connecting with and
  /// provides necessary contact details.
  ///
  /// - [publishAsGroup] - Boolean value to publish offer as group offer.
  ///
  /// - [offerDescription] - Description of the offer to indicate the purpose of
  /// the offer.
  ///
  /// - [customPhrase] - A custom phrase or keyword to help your offer be found
  /// more easily by specific searches on MeetingPlace. If not provided, a
  /// generic mnemonic will be used.
  ///
  /// - [validUntil] - The date and time when the offer expires.
  /// Once this date is reached, the offer will no longer be available.
  ///
  /// - [maximumUsage] - The maximum number of times the offer can be queried or
  /// accepted. Once this limit is reached, no further queries or acceptances
  /// will be allowed.
  ///
  /// - [mediatorDid] - The specific Mediator DID to be used for this offer.
  /// If not provided, the default SDK Mediator DID will be used.
  ///
  /// - [metadata] - The additional data related to the offer to be published.
  ///
  /// - [externalRef] - Application-specific data that is passed through to
  /// internal entities, such as connection offers and channels, and can be
  /// referenced later for tracking or identification purposes. [externalRef]
  /// is accessible on the current device only.
  ///
  /// **Returns:**
  /// - A [sdk.PublishOfferResult] object which includes the connection offer
  /// and the published offer DID manager.
  ///
  /// For group offers, it also includes the owner DID manager and the group
  /// DID manager.

  Future<sdk.PublishOfferResult<T>> publishOffer<T extends ConnectionOffer>({
    required String offerName,
    required sdk.SDKConnectionOfferType type,
    required VCard vCard,
    String? offerDescription,
    String? customPhrase,
    DateTime? validUntil,
    int? maximumUsage,
    String? mediatorDid,
    String? metadata,
    String? externalRef,
  }) async {
    if (type == sdk.SDKConnectionOfferType.groupInvitation) {
      final (connectionOffer, publishedOfferDid, ownerDid) =
          await _groupService.createGroup(
        offerName: offerName,
        offerDescription: offerDescription,
        customPhrase: customPhrase,
        validUntil: validUntil,
        maximumUsage: maximumUsage,
        mediatorDid: mediatorDid,
        externalRef: externalRef,
        metadata: metadata,
        vCard: vCard,
      );
      return sdk.PublishOfferResult(
        connectionOffer: connectionOffer as T,
        publishedOfferDidManager: publishedOfferDid,
        groupOwnerDidManager: ownerDid,
      );
    }

    final (connectionOffer, publishedOfferDid) =
        await _connectionService.publishOffer(
      wallet: wallet,
      offerName: offerName,
      offerDescription: offerDescription,
      type: type == SDKConnectionOfferType.outreachInvitation
          ? ConnectionOfferType.meetingPlaceOutreachInvitation
          : ConnectionOfferType.meetingPlaceInvitation,
      customPhrase: customPhrase,
      validUntil: validUntil,
      maximumUsage: maximumUsage,
      mediatorDid: mediatorDid,
      externalRef: externalRef,
      vCard: vCard,
    );

    return sdk.PublishOfferResult(
      connectionOffer: connectionOffer as T,
      publishedOfferDidManager: publishedOfferDid,
    );
  }

  /// Attempts to locate a previously published offer on MeetingPlace.
  /// This method searches for an existing offer using the provided [mnemonic].
  ///
  /// **Parameters:**
  /// - [mnemonic] The unique mnemonic identifier used to search for the offer.
  ///
  /// **Returns:**
  /// - [sdk.FindOfferResult] containing the details of the matched offer,
  /// or information indicating that no matching offer was found.

  Future<sdk.FindOfferResult> findOffer({required String mnemonic}) async {
    return _withSdkExceptionHandling(() async {
      final (connectionOffer, errorCode) = await _connectionService.findOffer(
        mnemonic: mnemonic,
      );

      return sdk.FindOfferResult(
        connectionOffer: connectionOffer,
        errorCode: errorCode,
      );
    });
  }

  /// Accepts an offer published by another party.
  ///
  /// **Parameters:**
  /// - [ConnectionOffer] - Connection offer object.
  ///
  /// - [vCard] - A VCard that contains information about who is accepting
  /// the offer. This helps the offeree to know who accepted the offer.
  ///
  /// - [externalRef] - Application-specific data that is passed through to
  /// internal entities, such as connection offers and channels, and can be
  /// referenced later for tracking or identification purposes. [externalRef]
  /// is accessible on the current device only.
  ///
  /// **Returns:**
  /// - A [sdk.AcceptOfferResult] object that provides the [connectionOffer],
  /// [acceptOfferDid] and [permanentChannelDid]

  Future<sdk.AcceptOfferResult<T>> acceptOffer<T extends ConnectionOffer>({
    required T connectionOffer,
    required VCard vCard,
    String? externalRef,
  }) async {
    return _withSdkExceptionHandling(() async {
      if (connectionOffer is GroupConnectionOffer) {
        final result = await _groupService.acceptGroupOffer(
          wallet: wallet,
          connectionOffer: connectionOffer,
          vCard: vCard,
          externalRef: externalRef,
        );

        return sdk.AcceptOfferResult(
          connectionOffer: result.connectionOffer as T,
          acceptOfferDid: result.acceptOfferDid,
          permanentChannelDid: result.permanentChannelDid,
        );
      }

      final result = await _connectionService.acceptOffer(
        wallet: wallet,
        connectionOffer: connectionOffer,
        vCard: vCard,
        externalRef: externalRef,
      );

      return sdk.AcceptOfferResult(
        connectionOffer: result.connectionOffer as T,
        acceptOfferDid: result.acceptOfferDid,
        permanentChannelDid: result.permanentChannelDid,
      );
    });
  }

  /// Notifies other party about acceptance of an offer.
  ///
  /// **Parameters:**
  /// - [ConnectionOffer] - ConnectionOffer object in the 'accepted' state
  /// - [senderInfo] - Sender information to be shown in notification message
  Future<void> notifyAcceptance({
    required ConnectionOffer connectionOffer,
    required String senderInfo,
  }) async {
    return _withSdkExceptionHandling(() async {
      if (connectionOffer is GroupConnectionOffer) {
        return _groupService.notifyAcceptance(
          connectionOffer: connectionOffer,
          senderInfo: senderInfo,
        );
      }
      return _connectionService.notifyAcceptance(
        connectionOffer: connectionOffer,
        senderInfo: senderInfo,
      );
    });
  }

  /// A method to allow the owner of the offer to approve connection request.
  ///
  /// This action updates both admin and group ACLs so that the member can
  /// communicate with admins and the entire group.
  ///
  /// A message of type [AtmMessageProtocol.groupMemberInauguration] is sent via
  /// mediator, informing the new member that their membership has been accepted
  /// using DIDComm protocol.
  ///
  /// The Meeting Place API is employed to add the member to a group on the backend,
  /// enabling subsequent message processing and triggering a push notification
  /// informing the new member about approval.
  ///
  /// **Parameters:**
  /// - [connectionOffer] - [GroupConnectionOffer] object for group.
  /// - [channel] - DID of member requesting membership
  ///
  /// **Returns:**
  /// Returns updated [Channel] instance.
  Future<Channel> approveConnectionRequest({
    required ConnectionOffer connectionOffer,
    required Channel channel,
  }) async {
    return _withSdkExceptionHandling(() async {
      return connectionOffer is GroupConnectionOffer
          ? await _groupService.approveMembershipRequest(
              connectionOffer: connectionOffer,
              channel: channel,
            )
          : await _connectionService.approveConnectionRequest(
              wallet: wallet,
              connectionOffer: connectionOffer,
              channel: channel,
            );
    });
  }

  /// A method that allows the owner of the offer to reject the connection request.
  ///
  /// **Parameters:**
  /// - [channel] - Specifies the channel of the entity to reject.

  Future<Group> rejectConnectionRequest({required Channel channel}) async {
    return _withSdkExceptionHandling(() async {
      if (channel.type == ChannelType.group) {
        return _groupService.rejectMembershipRequest(channel);
      }

      throw Exception('Not implemented');
    });
  }

  /// A method to leave channel. Depending on type of channel, it applies
  /// business logic to groups or individual channels.
  ///
  /// **Parameters:**
  /// - [channel] - Specifies the channel representing the connection.
  ///
  Future<void> leaveChannel(Channel channel) async {
    return _withSdkExceptionHandling(() async {
      if (channel.isGroup) return _groupService.leaveGroup(channel);
      await _connectionService.unlink(wallet: wallet, channel: channel);
    });
  }

  /// Encrypts and signs the message using the sender' s DID, then sends it to
  /// the [recipientDidDocument] via DIDComm.
  ///
  /// **Parameters:**
  /// - [message] - DIDComm plain text message
  /// - [senderDid] - DID used to send messages
  /// - [recipientDid] - DID of recipient.
  /// - [mediatorDid] - the Mediator DID
  /// - [notifyChannelType] - The notify channel type (currently its only chat_activity)
  /// - [ephemeral] - boolean value that indicates if the message is short live only.
  /// - [forwardExpiryInSeconds] - the forwrd expiry timer in seconds.

  Future<void> sendMessage(
    PlainTextMessage message, {
    required String senderDid,
    required String recipientDid,
    String? mediatorDid,
    String? notifyChannelType,
    bool? ephemeral,
    int? forwardExpiryInSeconds,
  }) async {
    return _withSdkExceptionHandling(() async {
      final senderDidManager = await _getDidManager(senderDid);
      final recipientDidDocument = await _didResolver.resolveDid(recipientDid);

      await _mediatorSDK.sendMessage(
        message,
        senderDidManager: senderDidManager,
        recipientDidDocument: recipientDidDocument,
        mediatorDid: mediatorDid,
        ephemeral: ephemeral,
        forwardExpiryInSeconds: forwardExpiryInSeconds,
      );

      if (notifyChannelType != null) {
        final channel = await _repositoryConfig.channelRepository
            .findChannelByDid(recipientDid);

        if (channel?.otherPartyNotificationToken != null) {
          await _controlPlaneSDK.execute(
            NotifyChannelCommand(
              notificationToken: channel!.otherPartyNotificationToken!,
              did: recipientDid,
              type: notifyChannelType, // TODO: make enum
            ),
          );
        }
      }
    });
  }

  /// Queues a message in the mediator for later sending.
  ///
  /// **Parameters:**
  /// - [message] - DIDComm plain text message
  /// - [senderDid] - DID used to send messages
  /// - [recipientDid] - DID of recipient.
  /// - [mediatorDid] - the Mediator DID
  /// - [ephemeral] - boolean value that indicates if the message is short live only.
  /// - [forwardExpiryInSeconds] - the forwrd expiry timer in seconds.

  Future<void> queueMessage(
    PlainTextMessage message, {
    required String senderDid,
    required String recipientDid,
    String? mediatorDid,
    bool? ephemeral,
    int? forwardExpiryInSeconds,
  }) async {
    return _withSdkExceptionHandling(() async {
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

  /// A method that allows a user to send a message to a group using the group's
  /// [recipientDidDocument] via DIDComm.
  ///
  /// **Parameters:**
  /// - [message] - DIDComm plain text message
  /// - [senderDid] - DID used to send messages
  /// - [recipientDid] - DID of recipient. This is the DID of the group
  /// - [increaseSequenceNumber] - boolean value that inidicates if the
  /// sequence number increments for the message sent to the group.
  /// - [notify] - boolean value that indicates that a notification is sent to
  /// the group members. Always set to `true` by default.
  /// - [ephemeral] - boolean value that indicates if the message is short live only.
  /// - [forwardExpiryInSeconds] - the forwrd expiry timer in seconds.

  Future<void> sendGroupMessage(
    PlainTextMessage message, {
    required String senderDid,
    required String recipientDid,
    required bool increaseSequenceNumber,
    bool notify = true,
    bool ephemeral = false,
    int? forwardExpiryInSeconds,
  }) async {
    return _withSdkExceptionHandling(() async {
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

  /// Sends outreach invitation to owner of [outreachConnectionOffer].
  ///
  /// **Parameters:**
  /// - [outreachConnectionOffer] - The connection offer that receives the
  ///   outreach notification.
  /// - [inviteToConnectionOffer] - The connection offer the invitation refers
  ///   to.
  /// - [messageToInclude] - Message to include in DIDComm message
  Future<void> sendOutreachInvitation({
    required ConnectionOffer outreachConnectionOffer,
    required ConnectionOffer inviteToConnectionOffer,
    required String messageToInclude,
    required String senderInfo,
  }) {
    return _withSdkExceptionHandling(() {
      return _outreachService.sendOutreachInvitation(
        wallet: wallet,
        outreachConnectionOffer: outreachConnectionOffer,
        inviteToConnectionOffer: inviteToConnectionOffer,
        messageToInclude: messageToInclude,
        senderInfo: senderInfo,
      );
    });
  }

  /// Fetches latest updates (notifications) from Control Plane API and
  /// handles each update event. This may need some time to happen. Therefore
  /// the function returns a stream that is going to receive a connection offer
  /// for each processed update event.
  ///
  /// **Parameters:**
  /// - [debounceDiscoveryEventsInSeconds] - Seconds to wait before fetching
  /// discovery events from discovery API.

  Future<void> processControlPlaneEvents({Function? onDone}) {
    return _withSdkExceptionHandling(
      () => _controlPlaneEventService.processEvents(
        debounceDiscoveryEventsInMilliseconds:
            _options.debounceDiscoveryEventsInMilliseconds,
        onDone: onDone,
      ),
    );
  }

  /// A method that closes active discovery events stream. This result in not pushing
  /// events to the stream when calling [deleteDiscoveryEvents].
  ///
  void disposeDiscoveryEventsStream() {
    _controlPlaneEventStreamManager.dispose();
  }

  /// A method that deletes all pending discovery events.

  Future<List<String>> deleteDiscoveryEvents() {
    return _controlPlaneEventService.deleteAll();
  }

  /// Retrieves available messages from the specified mediator instance
  /// [mediatorDid]. By setting [deleteOnRetrieve] to true, retrieved messages
  /// can be automatically deleted. The method takes care of checking message
  /// signatures and decrypts the messages if necessary.
  ///
  /// **Parameters:**
  /// - [did] - DID used to fetch messages from mediator.
  ///
  /// - [mediatorDid] - Optional mediator DID that can override the already
  /// registered mediator DID, if provided
  ///
  /// - [deleteOnRetrieve] - Boolean flag indicating whether messages should be
  /// deleted upon retrieval
  ///
  /// - [deleteFailedMessages] - Boolean flag indicating whether messages should be
  /// deleted upon failure
  ///
  /// **Returns:**
  /// - A [FetchMessageResult] object.

  Future<List<MediatorMessage>> fetchMessages({
    required String did,
    String? mediatorDid,
    bool deleteOnRetrieve = false,
    bool deleteFailedMessages = false,
  }) async {
    return _withSdkExceptionHandling(() async {
      final didManager = await _getDidManager(did);
      return _mediatorService.fetchMessages(
        didManager: didManager,
        mediatorDid: mediatorDid ?? _mediatorDid,
        options: FetchMessagesOptions(
          deleteFailedMessages: deleteFailedMessages,
          deleteOnRetrieve: deleteOnRetrieve,
        ),
      );
    });
  }

  /// A method to subscribes to incoming messages from the mediator.
  ///
  /// **Parameters:**
  /// - [did] - DID used to subscripe to mediator.
  ///
  /// - [mediatorDid]: Optional mediator DID to authenticate against.
  ///   If not provided, the SDK instance’s default mediator DID will be used.
  ///
  /// - [deleteOnMediator]: Indicates whether received messages should be
  ///   deleted from the mediator instance. If set to false, messages will
  ///   remain stored in the mediator.
  ///
  /// **Returns:**
  Future<MediatorStream> subscribeToMediator(
    String did, {
    String? mediatorDid,
    bool deleteOnMediator = true,
  }) async {
    return _withSdkExceptionHandling(() async {
      final didManager = await _getDidManager(did);
      return _mediatorService.subscribeToMessages(
        didManager: didManager,
        mediatorDid: mediatorDid ?? _mediatorDid,
        deleteOnMediator: deleteOnMediator,
      );
    });
  }

  /// Returns connection offer identified by [offerLink] from storage.
  ///
  /// **Parameters:**
  /// [offerLink] - ID of the offer.
  ///
  /// **Returns:**
  /// - [ConnectionOffer] or `null`

  Future<ConnectionOffer?> getConnectionOffer(String offerLink) {
    return _repositoryConfig.connectionOfferRepository
        .getConnectionOfferByOfferLink(offerLink);
  }

  /// Marks connection offer as deleted - updates connection offer status to
  /// deleted. If connection offer is already marked as deleted, delete
  /// operation is going to be skipped.
  ///
  /// **Parameters:**
  /// [connectionOffer] - [ConnectionOffer] instance.
  ///
  /// **Returns:**
  /// - [ConnectionOffer] object with the attribute isDeleted = true

  Future<ConnectionOffer> markConnectionOfferAsDeleted(
    ConnectionOffer connectionOffer,
  ) {
    return _connectionService.markConnectionOfferAsDeleted(connectionOffer);
  }

  /// Deletes connection offer from storage.
  ///
  /// **Parameters:**
  /// - [connectionOffer] - [ConnectionOffer] instance.

  Future<void> deleteConnectionOffer(ConnectionOffer connectionOffer) {
    return _connectionService.deleteConnectionOffer(connectionOffer);
  }

  /// Returns group identified by [offerLink] from storage.
  ///
  /// **Parameters:**
  /// [offerLink] - ID of the offer.
  ///
  /// **Returns:**
  /// - [Group] or `null`

  Future<Group?> getGroupByOfferLink(String offerLink) {
    return _groupService.getGroupByOfferLink(offerLink);
  }

  /// Returns group identified by [groupId] from storage.
  ///
  /// **Parameters:**
  /// [groupId] - ID of the group.
  ///
  /// **Returns:**
  /// - [Group] or `null`

  Future<Group?> getGroupById(String groupId) {
    return _groupService.getGroupById(groupId);
  }

  /// Updates an existing group in the repository by using repository method
  /// `updateGroup`.
  ///
  /// **Parameters:**
  /// [group] - Specifies the channel entity to update.

  Future<void> updateGroup(Group group) async {
    await _repositoryConfig.groupRepository.updateGroup(group);
  }

  /// Returns a list of all connection offers from repository by using
  /// repository method `listConnectionOffers`.
  ///
  /// **Returns:**
  /// - list of objects with type [ConnectionOffer].

  Future<List<ConnectionOffer>> listConnectionOffers() {
    return _repositoryConfig.connectionOfferRepository.listConnectionOffers();
  }

  Future<DidManager> _getDidManager(String did) {
    return _connectionManager.getDidManagerForDid(wallet, did);
  }

  /// Fetches a channel entity from the repository by using repository method
  /// `getChannelByDid` method.
  ///
  /// **Parameters:**
  /// [did] - The DID to match the channel either by `permanentChannelDid` or
  /// `otherPartyPermanentChannelDid`.
  ///
  /// **Returns:**
  /// - The matching [Channel] if found, or `null` if no match exists.

  Future<Channel?> getChannelByDid(String did) {
    return _repositoryConfig.channelRepository.findChannelByDid(did);
  }

  /// Fetches a channel entity from the repository by using repository method
  /// `findChannelByOtherPartyPermanentChannelDid` method.
  ///
  /// **Parameters:**
  /// [did] - the other party's permanent channel DID.
  ///
  /// **Returns:**
  /// - The matching [Channel] if found, or `null` if no match exists.

  Future<Channel?> getChannelByOtherPartyPermanentDid(String did) {
    return _repositoryConfig.channelRepository
        .findChannelByOtherPartyPermanentChannelDid(did);
  }

  /// Updates an existing channel in the repository.
  ///
  /// **Parameters:**
  /// [channel] - Specifies the channel entity to update.

  Future<void> updateChannel(Channel channel) {
    return _repositoryConfig.channelRepository.updateChannel(channel);
  }

  /// Updates an existing channel in the repository.
  ///
  /// **Parameters:**
  /// [channel] - Specifies the channel entity to update.

  Future<String?> getMediatorDidFromUrl(String mediatorEndpoint) {
    return _mediatorSDK.getMediatorDidFromUrl(mediatorEndpoint);
  }

  Future<T> _withSdkExceptionHandling<T>(Future<T> Function() operation) async {
    final methodName = '_withSdkExceptionHandling';

    try {
      return await operation();
    } on SDKException catch (e, stackTrace) {
      Error.throwWithStackTrace(
        MeetingPlaceCoreSDKException(
          message: e.message,
          code: e.code.value,
          innerException: e.innerException ?? e,
        ),
        stackTrace,
      );
    } on ControlPlaneSDKException catch (e, stackTrace) {
      _logger.error(
        'Failed to execute ControlPlane SDK operation:',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        MeetingPlaceCoreSDKException(
          message: e.message,
          code: e.code,
          innerException: e.innerException,
        ),
        stackTrace,
      );
    } on MeetingPlaceMediatorSDKException catch (e, stackTrace) {
      Error.throwWithStackTrace(
        MeetingPlaceCoreSDKException(
          message: 'Failure on MeetingPlaceCore SDK operation',
          code: e.code,
          innerException: e,
        ),
        stackTrace,
      );
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        MeetingPlaceCoreSDKException(
          message: e.toString(),
          code: 'generic',
          innerException: e,
        ),
        stackTrace,
      );
    }
  }
}
