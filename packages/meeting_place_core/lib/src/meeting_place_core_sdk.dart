import 'dart:async';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ContactCard;
import 'package:meeting_place_mediator/meeting_place_mediator.dart'
    show
        DefaultMeetingPlaceMediatorSDKLogger,
        MeetingPlaceMediatorSDK,
        MeetingPlaceMediatorSDKOptions;
import 'package:ssi/ssi.dart';

import '../meeting_place_core.dart';
import 'constants/sdk_constants.dart';
import 'event_handler/control_plane_event_handler_manager.dart';
import 'event_handler/control_plane_event_stream_manager.dart';
import 'loggers/logger_adapter.dart';
import 'sdk/sdk.dart' as sdk;
import 'sdk/sdk_error_handler.dart';
import 'service/channel/channel_service.dart';
import 'service/config.dart';
import 'service/connection_manager/connection_manager.dart';
import 'service/connection_offer/connection_offer_service.dart';
import 'service/connection_service.dart';
import 'service/control_plane_event_service.dart';
import 'service/group.dart';
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
    required String mediatorDid,
    required String controlPlaneDid,
    required MeetingPlaceCoreSDKOptions options,
    required SDKErrorHandler sdkErrorHandler,
    required DIDCommTransport didcommTransport,
    required MatrixService matrixService,
    required MessageService messageService,
    required Future<DidManager> Function(String did) getDidManager,
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
         errorHandler: sdkErrorHandler,
       );

  final Wallet wallet;
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
  final MeetingPlaceCoreSDKOptions _options;
  final SDKErrorHandler _sdkErrorHandler;

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

    final identityService = IdentityService(
      connectionManager: connectionManager,
      matrixService: matrixService,
    );

    final connectionService = ConnectionService(
      connectionOfferRepository: repositoryConfig.connectionOfferRepository,
      channelService: channelService,
      connectionManager: connectionManager,
      identityService: identityService,
      controlPlaneSDK: controlPlaneSDK,
      mediatorAclService: MediatorAclService(
        mediatorSDK: mediatorSDK,
        connectionManager: connectionManager,
        logger: mpxLogger,
      ),
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
        onAttachmentsReceived: options.onAttachmentsReceived,
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

    final messageService = MessageService(
      connectionManager: connectionManager,
      didResolver: didResolver,
      mediatorService: mediatorService,
      channelService: channelService,
      controlPlaneSDK: controlPlaneSDK,
      logger: mpxLogger,
    );

    final oobService = OobService(
      wallet: wallet,
      mediatorService: mediatorService,
      connectionService: connectionService,
      connectionManager: connectionManager,
      identityService: identityService,
      channelService: channelService,
      matrixService: matrixService,
      controlPlaneSDK: controlPlaneSDK,
      controlPlaneEventStreamManager: discoveryEventStreamManager,
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

    Future<DidManager> matrixTransportGetDidManager(String did) =>
        connectionManager.getDidManagerForDid(wallet, did);

    return MeetingPlaceCoreSDK._(
      wallet: wallet,
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
      mediatorDid: mediatorDid,
      controlPlaneDid: controlPlaneDid,
      options: options,
      sdkErrorHandler: sdkErrorHandler,
      didcommTransport: didcommTransport,
      matrixService: matrixService,
      messageService: messageService,
      getDidManager: matrixTransportGetDidManager,
    );
  }

  /// Returns instance of used low level [ControlPlaneSDK].
  ControlPlaneSDK get discovery => _controlPlaneSDK;

  /// Returns instance of used low level [MeetingPlaceMediatorSDK].
  ///
  /// Exposes mediator-side admin operations such as ACL updates and
  /// out-of-band invitation management.
  MeetingPlaceMediatorSDK get mediator => _mediatorSDK;

  /// Returns the [MeetingPlaceCoreSDKOptions] used to configure the SDK.
  MeetingPlaceCoreSDKOptions get options => _options;

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
          contactCard: contactCard,
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
  }) async {
    return _withSdkExceptionHandling(() async {
      return channel.isGroup
          ? await _groupService.approveMembershipRequest(channel: channel)
          : await _connectionService.approveConnectionRequest(
              wallet: wallet,
              channel: channel,
              attachments: attachments,
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

  /// A method that closes active discovery events stream. This result in not
  /// pushing
  /// events to the stream when calling [deleteControlPlaneEvents].
  void disposeControlPlaneEventsStream() {
    _controlPlaneEventStreamManager.dispose();
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

  /// Sends [message] through its transport (Matrix or DIDComm).
  ///
  /// Returns the Matrix event id for [MatrixOutgoingMessage] (or `null` for
  /// matrix events that don't produce one, such as `m.read`, `m.typing`,
  /// `m.room.redaction`). Always returns `null` for [DidCommOutgoingMessage].
  Future<String?> sendMessage(OutgoingMessage message) =>
      _messagingService.sendMessage(message);

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
}
