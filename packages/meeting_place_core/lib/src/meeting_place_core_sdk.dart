import 'dart:async';
import 'dart:typed_data';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ContactCard;
import 'package:meeting_place_mediator/meeting_place_mediator.dart'
    show
        DefaultMeetingPlaceMediatorSDKLogger,
        MeetingPlaceMediatorSDK,
        MeetingPlaceMediatorSDKOptions;
import 'package:meta/meta.dart';
import 'package:ssi/ssi.dart';

import '../meeting_place_core.dart';
import 'constants/sdk_constants.dart';
import 'event_handler/control_plane_event_handler_manager.dart';
import 'event_handler/control_plane_event_stream_manager.dart';
import 'loggers/logger_adapter.dart';
import 'sdk/sdk.dart' as sdk;
import 'sdk/sdk_error_handler.dart';
import 'service/agent_identity_service.dart';
import 'service/channel/channel_service.dart';
import 'service/connection_manager/connection_manager.dart';
import 'service/connection_offer/connection_offer_service.dart';
import 'service/connection_service.dart';
import 'service/control_plane_event_service.dart';
import 'service/group.dart';
import 'service/identity/did_web_document_service.dart';
import 'service/identity/identity_service.dart';
import 'service/mediator/mediator_acl_service.dart';
import 'service/mediator/mediator_service.dart';
import 'service/message/message_service.dart';
import 'service/notification_service/notification_service.dart';
import 'service/oob/oob_service.dart';
import 'service/outreach/outreach_service.dart';
import 'utils/cached_did_resolver.dart';

/// # Meeting Place Core SDK
/// The Affinidi Meeting Place - Core SDK provides a high-level interface for
/// coordinating connection setup using the discovery control plane API and
/// mediator. This SDK acts as an orchestrator, applying business logic on top
/// of underlying APIs to simplify integration.
/// ## Discovery Event Stream
/// The DiscoveryEventStream exposes a stream that can be listened to, pushing
/// each event after applying business logic within the SDK. The
/// processEventStream method triggers this process, using a debounce mechanism
/// to call the API at most once every second. This ensures efficient
/// processing and keeps the main isolate available for background tasks.
/// To improve performance and responsiveness, the event stream processing runs
/// in a separate Dart isolate.
/// ## Device
/// The Device object is used be provided once and reused throughout the entire
/// flow. If it changes, you can easily update it without affecting other parts
/// of your application.
/// ## Error Handling
/// All methods within this SDK throw a unified MeetingPlaceCoreSDKException,
/// which includes:
/// * A message providing context about the error
/// * A code that can be used to map specific error messages based on consumer
///   requirements
/// * A stacktrace for identifying the root cause of the issue
/// By using a consistent exception type, you can easily handle and respond to
/// errors in your application.
///
/// Example:
/// ```dart
/// final wallet = PersistentWallet(InMemoryKeyStore())
/// final storage = InMemoryStorage();
/// final repositoryConfig = RepositoryConfig(
/// connectionOfferRepository: ConnectionOfferRepositoryImpl(storage: storage),
///   groupRepository: GroupRepositoryImpl(storage: storage),
///   channelRepository: ChannelRepositoryImpl(storage: storage),
///   keyRepository: KeyRepositoryImpl(storage: storage),
/// );
///
/// final sdk = MeetingPlaceCoreSDK.create(
///   wallet: wallet,
///   repositoryConfig: repositoryConfig,
///   config: MatrixConfig(
///     mediatorDid: '<YOUR-MEDIATOR-DID:.well-known>',
///     controlPlaneDid: '<YOUR-CONTROL-PLANE-DID>',
///     homeserver: Uri.parse('https://matrix.example.com'),
///     databaseFactory: const UnsupportedMatrixDatabaseFactory(),
///     deviceId: '<YOUR-DEVICE-ID>',
///   ),
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
  /// fields, while others are assigned to private fields via the initializer
  /// list.
  ///
  /// ### Parameters
  /// - `wallet` (`Wallet`): The wallet instance used for cryptographic
  ///   operations.
  /// - `repositoryConfig` (`RepositoryConfig`): Configuration for repository
  ///   storage.
  /// - `controlPlaneDid` (`String`): The DID (Decentralized Identifier) of
  ///   this service.
  /// - `mediatorSDK` (`MediatorSDK`): Instance of the mediator SDK used for
  ///   routing messages.
  /// - `controlPlaneSDK` (`ControlPlaneSDK`): Instance of the control plane
  ///   SDK for discovering other agents.
  /// - `connectionManager` (`ConnectionManager`): Manages connections between
  ///   agents.
  /// - `connectionService` (`ConnectionService`): Service that handles
  ///   connection protocols.
  /// - `discoveryEventService` (`DiscoveryEventService`): Service that handles
  ///   discovery events.
  /// - `discoveryEventStreamManager` (`DiscoveryEventStreamManager`): Manages
  ///   streaming of discovery events.
  /// - `groupService` (`GroupService`): Handles group-related operations.
  /// - `outreachService` (`OutreachService`): Handles outreach notifications
  /// - `messageService` (`MessageService`): Handles message sending and
  ///   receiving.
  /// - `didResolver` (`DidResolver`): Resolves DIDs to their corresponding DID
  ///   Documents.
  /// - `mediatorDid` (`String`): The DID of the mediator agent.
  /// - `channelService` (`ChannelService`): Handles channel-related operations.
  ///
  /// ### Notes
  /// - Parameters marked as `required` must be provided when creating an
  ///   instance.
  /// - The initializer list (`: _repositoryConfig = repositoryConfig, ...`) is
  ///   used to assign values to private fields that cannot be assigned
  ///   directly using `this`.
  MeetingPlaceCoreSDK._({
    required this.wallet,
    required this.rootDid,
    required RepositoryConfig repositoryConfig,
    required MeetingPlaceMediatorSDK mediatorSDK,
    required ControlPlaneSDK controlPlaneSDK,
    required ConnectionManager connectionManager,
    required ConnectionService connectionService,
    required ControlPlaneEventService controlPlaneEventService,
    required ControlPlaneEventStreamManager controlPlaneEventStreamManager,
    required GroupService groupService,
    required NotificationService notificationService,
    required OutreachService outreachService,
    required OobService oobService,
    required ChannelService channelService,
    required IdentityService identityService,
    required AgentIdentityService agentIdentityService,
    required String mediatorDid,
    required String controlPlaneDid,
    required MeetingPlaceCoreSDKOptions options,
    required SDKErrorHandler sdkErrorHandler,
    required DIDCommTransport didcommTransport,
    required MatrixService matrixService,
    required MessageService messageService,
    required Future<DidManager> Function(String did) getDidManager,
    required StreamController<ChannelAttachmentEvent>
    channelAttachmentsController,
    required VdipClient vdipClient,
  }) : _repositoryConfig = repositoryConfig,
       _mediatorSDK = mediatorSDK,
       _controlPlaneSDK = controlPlaneSDK,
       _connectionManager = connectionManager,
       _connectionService = connectionService,
       _controlPlaneEventService = controlPlaneEventService,
       _controlPlaneEventStreamManager = controlPlaneEventStreamManager,
       _groupService = groupService,
       _notificationService = notificationService,
       _outreachService = outreachService,
       _oobService = oobService,
       _channelService = channelService,
       _identityService = identityService,
       _agentIdentityService = agentIdentityService,
       _mediatorDid = mediatorDid,
       _controlPlaneDid = controlPlaneDid,
       _options = options,
       _sdkErrorHandler = sdkErrorHandler,
       _didcomm = didcommTransport,
       _messagingService = MessagingService(
         matrixService: matrixService,
         messageService: messageService,
         channelService: channelService,
         groupRepository: repositoryConfig.groupRepository,
         didcomm: didcommTransport,
         getDidManager: getDidManager,
       ),
       _channelAttachmentsController = channelAttachmentsController,
       _vdipClient = vdipClient;

  final Wallet wallet;

  /// The root DID derived from the wallet mnemonic.
  final String rootDid;

  final RepositoryConfig _repositoryConfig;
  final MeetingPlaceMediatorSDK _mediatorSDK;
  final ControlPlaneSDK _controlPlaneSDK;
  final ConnectionManager _connectionManager;
  final ConnectionService _connectionService;
  final ControlPlaneEventService _controlPlaneEventService;
  final ControlPlaneEventStreamManager _controlPlaneEventStreamManager;
  final GroupService _groupService;
  final NotificationService _notificationService;
  final OutreachService _outreachService;
  final OobService _oobService;
  final ChannelService _channelService;
  final IdentityService _identityService;
  final AgentIdentityService _agentIdentityService;
  final MeetingPlaceCoreSDKOptions _options;
  final SDKErrorHandler _sdkErrorHandler;
  final StreamController<ChannelAttachmentEvent> _channelAttachmentsController;
  final VdipClient _vdipClient;

  final DIDCommTransport _didcomm;
  final MessagingService _messagingService;

  String _mediatorDid;
  final String _controlPlaneDid;

  static const String _className = 'MeetingPlaceCoreSDK';

  /// A static method that creates an instance of [MeetingPlaceCoreSDK].
  ///
  /// **Parameters:**
  /// - [wallet]: A digital wallet to manage cryptographic keys supporting
  /// different algorithms for signing and verifying VC and VP.
  /// - [repositoryConfig]: A repository object which defines the storage,
  /// group, key and channel repository objects.
  /// - [config]: Base SDK configuration. Pass [MatrixConfig] to enable
  ///   matrix-backed features, or [Config] for mediator/control-plane-only
  ///   initialization.
  /// - [options]: Instance of [MeetingPlaceCoreSDKOptions]
  ///
  /// **Returns:**
  /// - [MeetingPlaceCoreSDK] instance with all the required instance
  ///   parameters.
  static Future<MeetingPlaceCoreSDK> create({
    required Wallet wallet,
    required RepositoryConfig repositoryConfig,
    required Config config,
    MeetingPlaceCoreSDKOptions options = const MeetingPlaceCoreSDKOptions(),
    MeetingPlaceCoreSDKLogger? logger,
  }) async {
    final methodName = 'create';
    final mediatorDid = config.mediatorDid;
    final controlPlaneDid = config.controlPlaneDid;

    final channelAttachmentsController =
        StreamController<ChannelAttachmentEvent>.broadcast();

    final mpxLogger = LoggerAdapter(
      className: _className,
      sdkName: coreSDKName,
      logger: logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className),
    );

    mpxLogger.info('Starting Core SDK initialization', name: methodName);

    final controlPlaneLogger = LoggerAdapter(
      className: ControlPlaneSDK.className,
      sdkName: controlPlaneSDKName,
      logger: logger ?? DefaultControlPlaneSDKLogger(),
    );

    final mediatorLogger = LoggerAdapter(
      className: MeetingPlaceMediatorSDK.className,
      sdkName: mediatorSDKName,
      logger: logger ?? DefaultMeetingPlaceMediatorSDKLogger(),
    );

    final didResolver = CachedDidResolver(
      resolverAddress: options.didResolverAddress,
      logger: mpxLogger,
    );

    final channelService = ChannelService(
      channelRepository: repositoryConfig.channelRepository,
    );

    final offerService = ConnectionOfferService(
      connectionOfferRepository: repositoryConfig.connectionOfferRepository,
      channelService: channelService,
    );

    final connectionManager = ConnectionManager(
      keyRepository: repositoryConfig.keyRepository,
      logger: mpxLogger,
    );

    final didManager = await connectionManager.generateRootDid(wallet);
    final rootDidDoc = await didManager.getDidDocument();
    final rootDid = rootDidDoc.id;

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
        idleTimeout: options.idleTimeout,
      ),
      logger: controlPlaneLogger,
    );

    final mediatorSDK = MeetingPlaceMediatorSDK(
      mediatorDid: mediatorDid,
      didResolver: didResolver,
      logger: mediatorLogger,
      options: MeetingPlaceMediatorSDKOptions(
        maxRetries: options.maxRetries,
        maxRetriesDelay: options.maxRetriesDelay,
        signatureScheme: options.signatureScheme,
        expectedMessageWrappingTypes: options.expectedMessageWrappingTypes,
      ),
    );

    if (config is! MatrixConfig) {
      // TODO(MA): Allow creating a setup that does not need matrix and can work
      // with any mediator that implements the expected interfaces,
      // like in the original version of the SDK. This will require some
      // refactoring to separate the core logic from matrix-specific
      // implementations, but will make the SDK more flexible and adaptable to
      // different environments and use cases.
      throw UnsupportedError(
        '''Unsupported config type. Expected MatrixConfig for this version of the SDK.''',
      );
    }

    final matrixService = MatrixService(
      config: config,
      controlPlaneSDK: controlPlaneSDK,
      logger: mpxLogger,
    );

    final mediatorService = MediatorService(
      mediatorSDK: mediatorSDK,
      keyRepository: repositoryConfig.keyRepository,
      logger: mpxLogger,
    );

    if (options.agentDid case final agentDid?) {
      await mediatorService.updateAcl(
        ownerDidManager: didManager,
        mediatorDid: mediatorDid,
        acl: AccessListAdd(ownerDid: rootDid, granteeDids: [agentDid]),
      );
    }

    final messageService = MessageService(
      connectionManager: connectionManager,
      didResolver: didResolver,
      mediatorService: mediatorService,
      channelService: channelService,
      controlPlaneSDK: controlPlaneSDK,
      logger: mpxLogger,
    );

    final identityService = IdentityService(
      connectionManager: connectionManager,
      matrixService: matrixService,
      didWebDocumentService: DidWebDocumentService(
        controlPlaneSDK: controlPlaneSDK,
        rootDidManager: didManager,
        audience: controlPlaneDid,
      ),
      didWebBaseHost: _didWebBaseHostFromControlPlaneDid(controlPlaneDid),
      messageService: messageService,
      mediatorService: mediatorService,
      mediatorDid: mediatorDid,
      agentDid: options.agentDid,
    );

    final mediatorAclService = MediatorAclService(
      mediatorSDK: mediatorSDK,
      connectionManager: connectionManager,
      logger: mpxLogger,
    );

    final connectionService = ConnectionService(
      connectionOfferRepository: repositoryConfig.connectionOfferRepository,
      channelService: channelService,
      connectionManager: connectionManager,
      identityService: identityService,
      controlPlaneSDK: controlPlaneSDK,
      mediatorAclService: mediatorAclService,
      mediatorSDK: mediatorSDK,
      offerService: offerService,
      didResolver: didResolver,
      matrixService: matrixService,
      logger: mpxLogger,
    );

    // TODO: rename
    final discoveryEventStreamManager = ControlPlaneEventStreamManager(
      logger: mpxLogger,
    );

    final groupService = GroupService(
      wallet: wallet,
      connectionManager: connectionManager,
      connectionOfferRepository: repositoryConfig.connectionOfferRepository,
      connectionService: connectionService,
      groupRepository: repositoryConfig.groupRepository,
      channelService: channelService,
      keyRepository: repositoryConfig.keyRepository,
      controlPlaneSDK: controlPlaneSDK,
      mediatorSDK: mediatorSDK,
      offerService: offerService,
      identityService: identityService,
      matrixService: matrixService,
      didResolver: didResolver,
      logger: mpxLogger,
    );

    final vdipClient = VdipClient(
      messageService: messageService,
      channelService: channelService,
      connectionManager: connectionManager,
      wallet: wallet,
      mediatorService: mediatorService,
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
      channelService: channelService,
      streamManager: discoveryEventStreamManager,
      matrixService: matrixService,
      identityService: identityService,
      didResolver: didResolver,
      options: ControlPlaneEventHandlerManagerOptions(
        maxRetries: options.eventHandlerMessageFetchMaxRetries,
        maxRetriesDelay: options.eventHandlerMessageFetchMaxRetriesDelay,
        messageTypesForSequenceTracking:
            options.messageTypesForSequenceTracking,
        onBuildAttachments: options.onBuildAttachments,
        onAttachmentsReceived: (channel, attachments) =>
            channelAttachmentsController.add(
              ChannelAttachmentEvent(
                channel: channel,
                attachments: attachments,
              ),
            ),
        agentDid: options.agentDid,
      ),
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

    final oobService = OobService(
      wallet: wallet,
      mediatorService: mediatorService,
      connectionService: connectionService,
      connectionManager: connectionManager,
      identityService: identityService,
      channelService: channelService,
      controlPlaneSDK: controlPlaneSDK,
      controlPlaneEventStreamManager: discoveryEventStreamManager,
      onAttachmentsReceived: (channel, attachments) =>
          channelAttachmentsController.add(
            ChannelAttachmentEvent(channel: channel, attachments: attachments),
          ),
      logger: mpxLogger,
    );

    mpxLogger.info('Completed initializing CoreSDK', name: methodName);

    final sdkErrorHandler = SDKErrorHandler(logger: mpxLogger);

    final didcommTransport = DIDCommTransport(
      mediatorSDK: mediatorSDK,
      messageService: messageService,
      mediatorService: mediatorService,
      didResolver: didResolver,
      errorHandler: sdkErrorHandler,
      getDidManager: (did) =>
          connectionManager.getDidManagerForDid(wallet, did),
      defaultMediatorDid: mediatorDid,
      expectedMessageWrappingTypes: options.expectedMessageWrappingTypes,
    );

    final agentIdentityService = AgentIdentityService(
      identityService: identityService,
      mediatorAclService: mediatorAclService,
      didcommTransport: didcommTransport,
      channelRepository: repositoryConfig.channelRepository,
      wallet: wallet,
      connectionManager: connectionManager,
      matrixService: matrixService,
    );

    Future<DidManager> matrixTransportGetDidManager(String did) =>
        connectionManager.getDidManagerForDid(wallet, did);

    return MeetingPlaceCoreSDK._(
      wallet: wallet,
      rootDid: rootDid,
      repositoryConfig: repositoryConfig,
      mediatorSDK: mediatorSDK,
      controlPlaneSDK: controlPlaneSDK,
      connectionManager: connectionManager,
      connectionService: connectionService,
      controlPlaneEventService: discoveryEventService,
      controlPlaneEventStreamManager: discoveryEventStreamManager,
      groupService: groupService,
      notificationService: notificationService,
      outreachService: outreachService,
      oobService: oobService,
      channelService: channelService,
      identityService: identityService,
      agentIdentityService: agentIdentityService,
      mediatorDid: mediatorDid,
      controlPlaneDid: controlPlaneDid,
      options: options,
      sdkErrorHandler: sdkErrorHandler,
      didcommTransport: didcommTransport,
      matrixService: matrixService,
      messageService: messageService,
      getDidManager: matrixTransportGetDidManager,
      channelAttachmentsController: channelAttachmentsController,
      vdipClient: vdipClient,
    );
  }

  /// Returns instance of used low level [ControlPlaneSDK].
  ControlPlaneSDK get discovery => _controlPlaneSDK;

  /// Returns instance of used low level [MeetingPlaceMediatorSDK].
  ///
  /// Exposes mediator-side admin operations such as ACL updates and
  /// out-of-band invitation management.
  MeetingPlaceMediatorSDK get mediator => _mediatorSDK;

  /// Returns the [VdipClient] for sending and receiving VRC credentials
  /// over the shared DIDComm connection.
  VdipClient get vdip => _vdipClient;

  /// Returns the [MeetingPlaceCoreSDKOptions] used to configure the SDK.
  MeetingPlaceCoreSDKOptions get options => _options;

  /// A broadcast stream that emits a [ChannelAttachmentEvent] whenever
  /// attachments arrive during connection establishment (channel inauguration
  /// or OOB acceptance).
  ///
  /// Subscribe to this stream to react to incoming attachments — for example,
  /// to extract and store R-Card credentials sent by the other party.
  Stream<ChannelAttachmentEvent> get channelAttachments =>
      _channelAttachmentsController.stream;

  /// Returns a stream of [ControlPlaneStreamEvent] events.
  ///
  /// To emit events based on pending notifications from the Control Plane API,
  /// call [processControlPlaneEvents]. Events are first processed internally
  /// before
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
    _didcomm.defaultMediatorDid = mediatorDid;
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
  /// Returns a [DidManager] instance
  Future<DidManager> generateDid() async {
    return _connectionManager.generateDid(wallet);
  }

  /// Generates a new `did:web` identity and registers its DID document with
  /// the control plane, using the same derivation path as permanent channel
  /// identities but without performing a Matrix login or an agent handshake.
  ///
  /// Returns a [DidManager] instance for the newly created DID.
  Future<DidManager> generateDidWeb() async {
    return _identityService.generateDidWeb(wallet);
  }

  /// Generates a fresh `did:web`, grants [otherPartyPermanentChannelDid]
  /// access on the mediator, and sends back an
  /// `agent-create-channel-identity-response` containing the new DID.
  ///
  /// - [agentDid]: The agent's own DID, used as the sender of the response.
  /// - [otherPartyPermanentChannelDid]: The per-channel DID of the party that
  ///   issued the request. Access is granted to this DID, and the response is
  ///   sent to it.
  /// - [mediatorDid]: The mediator through which the response is routed.
  ///
  /// Returns the new [DidManager] so the caller can subscribe to messages on
  /// the freshly created DID.
  Future<Channel> generateAgentIdentity({
    required String agentDid,
    required String otherPartyPermanentChannelDid,
    required String mediatorDid,
    required String offerLink,
    required String publishOfferDid,
    required ContactCard contactCard,
    required ChannelTransport transport,
    required String agentControllerDid,
  }) {
    return _agentIdentityService.createChannelIdentity(
      agentDid: agentDid,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      mediatorDid: mediatorDid,
      offerLink: offerLink,
      publishOfferDid: publishOfferDid,
      contactCard: contactCard,
      transport: transport,
      agentControllerDid: agentControllerDid,
    );
  }

  /// Handles an incoming `agent-channel-inauguration` message by granting
  /// [otherPartyPermanentChannelDid] access on the mediator, persisting a
  /// [ChannelStatus.inaugurated] [Channel], and returning it so the caller
  /// can open a chat session on [Channel.permanentChannelDid].
  Future<Channel> processAgentChannelInauguration({
    required String otherPartyPermanentChannelDid,
    required String otherPartyNotificationToken,
    required String agentPermanentChannelDid,
    ContactCard? contactCard,
    String? matrixRoomId,
  }) {
    return _agentIdentityService.processAgentChannelInauguration(
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      otherPartyNotificationToken: otherPartyNotificationToken,
      agentPermanentChannelDid: agentPermanentChannelDid,
      contactCard: contactCard,
      matrixRoomId: matrixRoomId,
    );
  }

  /// Retrieves an existing [DidManager] for the specified DID string.
  ///
  /// This method looks up a previously generated DID in the key repository
  /// and reconstructs its corresponding [DidManager] instance using the
  /// provided [Wallet].
  ///
  /// **Parameters:**
  /// - [did] - The DID string to retrieve the manager for.
  ///
  /// Returns a [DidManager] instance for the specified DID.
  ///
  Future<DidManager> getDidManager(String did) {
    return _withSdkExceptionHandling(() {
      return _connectionManager.getDidManagerForDid(wallet, did);
    });
  }

  /// Test-only helper that drains a matrix sync cycle and forces device-key
  /// fetches for [expectedDids] on the matrix client owned by [localDid],
  /// returning once the room state and key catalog can support an encrypted
  /// send all expected recipients can decrypt. Production callers do not
  /// need this — see [MatrixService.waitForRoomEncryptionReady] for the
  /// underlying race it hides.
  @visibleForTesting
  Future<void> waitForRoomEncryptionReady({
    required String localDid,
    required Iterable<String> expectedDids,
    Duration timeout = const Duration(seconds: 15),
  }) {
    return _withSdkExceptionHandling(() {
      return _messagingService.waitForRoomEncryptionReady(
        localDid: localDid,
        expectedDids: expectedDids,
        timeout: timeout,
      );
    });
  }

  /// Creates an Out-Of-Band invitation for a User.
  ///
  /// **Parameters:**
  /// - [contactCard]: An object that contains information about who is offering
  ///   the
  ///   offer. This helps others know whom they are connecting with and provides
  ///   necessary contact details.
  ///
  /// - [did] - If specified, this DID is used as the permanent
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
  /// Returns [OobOfferSession]
  Future<OobOfferSession> createOobFlow({
    required ContactCard contactCard,
    String? type,
    String? did,
    String? mediatorDid,
    String? externalRef,
  }) async {
    return _withSdkExceptionHandling(() {
      return _oobService.createOobFlow(
        contactCard: contactCard,
        type: type,
        did: did,
        mediatorDid: mediatorDid ?? _mediatorDid,
        externalRef: externalRef,
      );
    });
  }

  /// Accepts an Out-Of-Band invitation created by a User.
  ///
  /// **Parameters:**
  /// - [oobUrl]: The OOB URL.
  ///
  /// - [contactCard]: An object that contains information about who is offering
  ///   the
  ///   offer. This helps others know whom they are connecting with and provides
  ///   necessary contact details.
  ///
  /// - [externalRef] - Application-specific data that is passed through to
  ///   internal oob entity and can be referenced later for tracking or
  ///   identification purposes. [externalRef] is accessible on the current
  ///   device only.
  ///
  /// - [attachments] - Optional list of attachments (e.g., R-Card credentials)
  ///   to include in the invitation acceptance message.
  ///
  /// Returns [OobAcceptanceSession]
  Future<OobAcceptanceSession> acceptOobFlow(
    Uri oobUrl, {
    required ContactCard contactCard,
    String? type,
    String? externalRef,
    String? did,
    List<Attachment>? attachments,
  }) async {
    return _withSdkExceptionHandling(() {
      return _oobService.acceptOobFlow(
        oobUrl,
        did: did,
        type: type,
        contactCard: contactCard,
        externalRef: externalRef,
        mediatorDid: _mediatorDid,
        attachments: attachments,
      );
    });
  }

  /// Validates whether a given offer phrase is already in use within the
  /// system.
  ///
  /// **Parameters:**
  /// - [phrase] - The offer phrase to be checked for availability.
  ///
  /// **Returns:**
  /// - A [sdk.ValidateOfferPhraseResult] object which provides isAvailable flag
  ///   that shows whether the offer
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
  /// notify the device about events in the Meeting Place flow and automatically
  /// included
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

  /// Registers for DIDComm notifications via the mediator.
  Future<RegisterForDidcommNotificationsResult>
  registerForDIDCommNotifications({String? mediatorDid, String? recipientDid}) {
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
  /// - [contactCard] - A ContactCard that contains information about who is
  /// offering the offer. This helps others know whom they are connecting with
  /// and provides necessary contact details.
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
    required ContactCard contactCard,
    required String offerDescription,
    String? customPhrase,
    DateTime? validUntil,
    int? maximumUsage,
    String? mediatorDid,
    String? metadata,
    String? externalRef,
    String? contextKey,
    ChannelTransport transport = ChannelTransport.didcomm,
    int? score,
  }) async {
    if (type == sdk.SDKConnectionOfferType.groupInvitation) {
      final (connectionOffer, publishedOfferDid, ownerDid) = await _groupService
          .createGroup(
            offerName: offerName,
            offerDescription: offerDescription,
            customPhrase: customPhrase,
            validUntil: validUntil,
            maximumUsage: maximumUsage,
            mediatorDid: mediatorDid ?? _mediatorDid,
            externalRef: externalRef,
            metadata: metadata,
            card: contactCard,
          );
      return sdk.PublishOfferResult(
        connectionOffer: connectionOffer as T,
        publishedOfferDidManager: publishedOfferDid,
        groupOwnerDidManager: ownerDid,
      );
    }

    final (connectionOffer, publishedOfferDid) = await _connectionService
        .publishOffer(
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
          contextKey: contextKey,
          contactCard: contactCard,
          transport: transport,
          score: score,
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
  /// - [contactCard] - A [ContactCard that contains information about who is
  ///   accepting the offer. This helps the offeree to know who accepted it.
  ///
  /// - [senderInfo] - Value to be shown in notification message to the other
  ///   party.
  ///
  /// - [externalRef] - Application-specific data that is passed through to
  ///   internal entities, such as connection offers and channels, and can be
  ///   referenced later for tracking or identification purposes. [externalRef]
  ///   is accessible on the current device only.
  ///
  /// **Returns:**
  /// - A [sdk.AcceptOfferResult] object
  Future<sdk.AcceptOfferResult<T>> acceptOffer<T extends ConnectionOffer>({
    required T connectionOffer,
    required ContactCard contactCard,
    required String senderInfo,
    String? externalRef,
    String? contextKey,
  }) async {
    return _withSdkExceptionHandling(() async {
      if (connectionOffer is GroupConnectionOffer) {
        final result = await _groupService.acceptGroupOffer(
          wallet: wallet,
          connectionOffer: connectionOffer,
          card: contactCard,
          senderInfo: senderInfo,
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
        contactCard: contactCard,
        senderInfo: senderInfo,
        externalRef: externalRef,
        contextKey: contextKey,
      );

      return sdk.AcceptOfferResult(
        connectionOffer: result.connectionOffer as T,
        acceptOfferDid: result.acceptOfferDid,
        permanentChannelDid: result.permanentChannelDid,
      );
    });
  }

  /// A method to allow the owner of the offer to approve connection request.
  ///
  /// This action updates both admin and group ACLs so that the member can
  /// communicate with admins and the entire group.
  ///
  /// A message of type [MeetingPlaceProtocol.groupMemberInauguration] is sent
  /// via
  /// mediator, informing the new member that their membership has been accepted
  /// using DIDComm protocol.
  ///
  /// The Meeting Place API is employed to add the member to a group on the
  /// backend,
  /// enabling subsequent message processing and triggering a push notification
  /// informing the new member about approval.
  ///
  /// **Parameters:**
  /// - [channel] - DID of member requesting membership
  /// - [attachments] - Optional list of attachments (e.g., R-Card credentials)
  ///   to include in the connection approval message
  ///
  /// **Returns:**
  /// Returns updated [Channel] instance.
  Future<Channel> approveConnectionRequest({
    required Channel channel,
    List<Attachment>? attachments,
    String? contextKey,
  }) async {
    return _withSdkExceptionHandling(() async {
      return channel.isGroup
          ? await _groupService.approveMembershipRequest(channel: channel)
          : await _connectionService.approveConnectionRequest(
              wallet: wallet,
              channel: channel,
              attachments: attachments,
              contextKey: contextKey,
            );
    });
  }

  /// A method that allows the owner of the offer to reject the connection
  /// request.
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
  Future<void> leaveChannel(Channel channel) async {
    return _withSdkExceptionHandling(() async {
      if (channel.isGroup) return _groupService.leaveGroup(channel);
      await _connectionService.unlink(wallet: wallet, channel: channel);
    });
  }

  /// Removes a member from a group as an owner-initiated moderation action.
  ///
  /// Authorization is enforced inside the SDK: only the wallet that manages
  /// `group.ownerDid` can successfully execute this. A non-owner caller is
  /// rejected with [MeetingPlaceCoreSDKErrorCode.groupCallerIsNotOwnerError].
  ///
  /// Removing the group owner is rejected with
  /// [MeetingPlaceCoreSDKErrorCode.groupCannotRemoveOwnerError]. Owners that
  /// want to leave their own group should use [leaveChannel] instead.
  ///
  /// **Parameters:**
  /// - [groupId] - Identifier of the group to remove the member from.
  /// - [memberDid] - DID of the member to remove.
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberDid,
  }) {
    return _withSdkExceptionHandling(() {
      return _groupService.removeMember(groupId: groupId, memberDid: memberDid);
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
  /// - [onDone] - A callback function that is called when the processing of
  ///   control plane events is complete.
  ///
  ///   It receives a list of errors that occurred during the processing of
  ///   control plane events.
  Future<void> processControlPlaneEvents({
    void Function(List<Object> errors)? onDone,
  }) {
    return _withSdkExceptionHandling(
      () => _controlPlaneEventService.processEvents(
        debounceEvents: options.debounceControlPlaneEvents,
        onDone: onDone,
      ),
    );
  }

  /// Closes the control plane events stream.
  ///
  /// After calling this, no further events will be emitted on
  /// [controlPlaneEventsStream]. Call this when the SDK is no longer needed
  /// (e.g. on sign-out) to release resources.
  void disposeControlPlaneEventsStream() {
    _controlPlaneEventStreamManager.dispose();
  }

  /// Releases all resources held by the SDK: closes the control plane
  /// events stream, aborts every cached matrix client's sync loop and
  /// closes their databases. Safe to call multiple times. After dispose
  /// the SDK instance must not be used further.
  Future<void> dispose() async {
    _controlPlaneEventStreamManager.dispose();
    await _messagingService.dispose();
  }

  /// Closes the [channelAttachments] broadcast stream.
  ///
  /// After calling this, no further events will be emitted on
  /// [channelAttachments]. Call this when the SDK is no longer needed
  /// (e.g. on sign-out) to release resources.
  Future<void> closeChannelAttachmentsStream() {
    return _channelAttachmentsController.close();
  }

  /// Disposes the [VdipClient] and closes the [vdip] incoming-messages stream.
  ///
  /// Call this when the SDK is no longer needed (e.g. on sign-out) to
  /// release resources held by the VDIP subsystem.
  Future<void> closeVdipStream() {
    return _vdipClient.dispose();
  }

  /// A method that deletes all pending discovery events.
  Future<List<String>> deleteControlPlaneEvents() {
    return _controlPlaneEventService.deleteAll();
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

  /// Retrieves all [ConnectionOffer] objects matching the given [externalRef].
  Future<List<ConnectionOffer>> getConnectionOffersByExternalRef(
    String externalRef,
  ) {
    return _repositoryConfig.connectionOfferRepository
        .getConnectionOffersByExternalRef(externalRef);
  }

  /// Updates the VRC score for the given [offers] on the Control Plane.
  ///
  /// [score] — the new trust score (VRC count) to set.
  /// [offers] — the published [ConnectionOffer] objects to update.
  Future<UpdateScoreForOffersResult> updateScoreForOffers({
    required int score,
    required List<ConnectionOffer> offers,
  }) {
    return _withSdkExceptionHandling(() async {
      final mnemonics = offers.map((o) => o.mnemonic).toList();
      final output = await _controlPlaneSDK.execute(
        UpdateOffersScoreCommand(score: score, mnemonics: mnemonics),
      );

      final updatedMnemonics = output.updatedOffers.toSet();
      for (final offer in offers) {
        if (updatedMnemonics.contains(offer.mnemonic)) {
          await _repositoryConfig.connectionOfferRepository
              .updateConnectionOffer(offer.copyWith(score: score));
        }
      }

      return UpdateScoreForOffersResult(
        updatedOffers: output.updatedOffers,
        failedOffers: output.failedOffers,
      );
    });
  }

  /// Updates the VRC score for [offers] in local storage only, without calling
  /// the control plane API.
  ///
  /// Use this for accepted (non-owned) offers where the local user cannot
  /// update the score remotely — for example, when B accepted A's published
  /// offer and needs to reflect an updated VRC count without owning the
  /// mnemonic on the control plane.
  ///
  /// **Parameters:**
  /// - [score] — the new trust score (VRC count) to persist locally.
  /// - [offers] — the accepted [ConnectionOffer] objects to update in the
  ///   local repository.
  Future<void> updateLocalConnectionOffersScore({
    required int score,
    required List<ConnectionOffer> offers,
  }) async {
    for (final offer in offers) {
      await _repositoryConfig.connectionOfferRepository.updateConnectionOffer(
        offer.copyWith(score: score),
      );
    }
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
    return _channelService.findChannelByDidOrNull(did);
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
    return _channelService.findChannelByOtherPartyPermanentChannelDidOrNull(
      did,
    );
  }

  /// Updates an existing channel in the repository.
  ///
  /// **Parameters:**
  /// [channel] - Specifies the channel entity to update.
  Future<void> updateChannel(Channel channel) {
    return _channelService.updateChannel(channel);
  }

  /// Resolves mediator DID from the given mediator endpoint URL.
  ///
  /// **Parameters:**
  /// - [mediatorEndpoint] - The URL of the mediator endpoint to resolve the DID
  ///
  /// **Returns:**
  /// - The resolved mediator DID as a string, or `null` if resolution fails.
  Future<String?> getMediatorDidFromUrl(String mediatorEndpoint) {
    return _mediatorSDK.getMediatorDidFromUrl(mediatorEndpoint);
  }

  /// Sends [fileBytes] as a media message on [channel]. The transport
  /// is selected from [Channel.transport]; encryption, upload, and messaging
  /// are delegated to the underlying transport.
  Future<String?> sendMediaMessage(
    Channel channel,
    Uint8List fileBytes, {
    required String contentType,
    String? filename,
    String? caption,
    Map<String, dynamic>? extraContent,
    ChannelNotification? notification,
  }) {
    return _messagingService.sendMediaMessage(
      channel,
      fileBytes,
      contentType: contentType,
      filename: filename,
      caption: caption,
      extraContent: extraContent,
      notification: notification,
    );
  }

  /// Downloads and decrypts the media identified by [reference] in [channel].
  Future<Uint8List> downloadMedia(Channel channel, MediaReference reference) {
    return _withSdkExceptionHandling(() {
      return _messagingService.downloadMedia(channel, reference);
    });
  }

  /// Sends [message] through its transport (Matrix or DIDComm).
  ///
  /// Returns the Matrix event id for [MatrixOutgoingMessage] (or `null` for
  /// matrix events that don't produce one, such as `m.read`, `m.typing`,
  /// `m.room.redaction`). Always returns `null` for [DidCommOutgoingMessage].
  Future<String?> sendMessage(OutgoingMessage message) {
    return _withSdkExceptionHandling(
      () => _messagingService.sendMessage(message),
    );
  }

  /// Subscribes to incoming messages for the given [subscription].
  ///
  /// The returned [IncomingMessageHandle] owns the underlying transport
  /// subscription. Callers MUST call [IncomingMessageHandle.dispose] when
  /// they are done; otherwise the potential subscriptions stay open
  /// and continue consuming messages from the server.
  Future<IncomingMessageHandle> subscribe(
    IncomingMessageSubscription subscription,
  ) => _messagingService.subscribe(subscription);

  /// Fetches historical messages for the given [query].
  Future<List<IncomingMessage>> fetchHistory(HistoryQuery query) =>
      _messagingService.fetchHistory(query);

  Future<T> _withSdkExceptionHandling<T>(Future<T> Function() operation) async {
    return _sdkErrorHandler.handleError(operation);
  }

  static Uri _didWebBaseHostFromControlPlaneDid(String controlPlaneDid) {
    var domain = controlPlaneDid.replaceFirst('did:web:', '');
    domain = domain.replaceAll('%3A', ':');
    domain = domain.replaceAll(':', '/');
    return Uri.parse('https://$domain');
  }
}
