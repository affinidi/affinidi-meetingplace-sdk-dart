import 'dart:async';

import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

import 'api/control_plane_api_client.dart';
import 'api/control_plane_api_client_options.dart';
import 'api/did_web_document_api.dart';
import 'command/accept_offer/accept_offer_handler.dart';
import 'command/accept_offer_group/accept_offer_group_handler.dart';
import 'command/authenticate/authenticate_handler.dart';
import 'command/command.dart';
import 'command/create_oob/create_oob_handler.dart';
import 'command/delete_pending_notifications/'
    'delete_pending_notifications_handler.dart';
import 'command/deregister_notification/deregister_notification_handler.dart';
import 'command/deregister_offer/deregister_offer_handler.dart';
import 'command/did_document_upload/did_document_upload_handler.dart';
import 'command/finalise_acceptance/finalise_acceptance_handler.dart';
import 'command/get_oob/get_oob_handler.dart';
import 'command/get_pending_notifications/get_pending_notifications_handler.dart';
import 'command/group_add_member/group_add_member_handler.dart';
import 'command/group_delete/group_delete_handler.dart';
import 'command/group_member_deregister/group_deregister_member_handler.dart';
import 'command/group_notify_channel/group_notify_channel_handler.dart';
import 'command/matrix_token/matrix_token_handler.dart';
import 'command/notify_acceptance/notify_acceptance_handler.dart';
import 'command/notify_acceptance_group/notify_acceptance_handler.dart';
import 'command/notify_channel/notify_channel_handler.dart';
import 'command/notify_outreach/notify_outreach_handler.dart';
import 'command/query_offer/query_offer_handler.dart';
import 'command/register_device/register_device_handler.dart';
import 'command/register_notification/register_notification_handler.dart';
import 'command/register_offer/register_offer_handler.dart';
import 'command/register_offer_group/register_offer_group_handler.dart';
import 'command/update_offers_score/update_offers_score_handler.dart';
import 'command/validate_offer_phrase/validate_offer_phrase_handler.dart';
import 'constants/sdk_constants.dart';
import 'core/command/command.dart';
import 'core/command/command_dispatcher.dart';
import 'core/device/device.dart';
import 'core/device/device_platform.dart';
import 'core/model/did_web_proof.dart';
import 'core/offer_type.dart';
import 'core/protocol/contact_card/contact_card.dart';
import 'core/protocol/transport.dart';
import 'core/sdk_error_handler.dart';
import 'loggers/default_meeting_place_control_plane_sdk_logger.dart';
import 'loggers/meeting_place_control_plane_sdk_logger.dart';
import 'meeting_place_control_plane_sdk_error_code.dart';
import 'meeting_place_control_plane_sdk_exception.dart';
import 'meeting_place_control_plane_sdk_options.dart';

/// Thrown internally when [MeetingPlaceControlPlaneSDK.device] is accessed
/// before a [Device] has been set on the SDK instance.
class MissingDeviceException implements Exception {}

/// The **MeetingPlaceControlPlaneSDK** provides the libraries to enable the
/// discovery of other participants to establish a connection and
/// communicate securely.
///
/// It enables participants to publish a connection offer to allow other
/// participants to communicate directly or through group chat.
/// Through discovery, organisations and AI agents can publish their
/// connection offers to allow users to connect and start using their services.
class MeetingPlaceControlPlaneSDK {
  /// Creates a new instance of [MeetingPlaceControlPlaneSDK].
  ///
  /// The [didManager] is the did manager object, [controlPlaneDid] is the
  /// control plane API DID string, [mediatorDid] is the mediator DID string,
  /// [controlPlaneSDKConfig] is the control plane SDK configuration object,
  /// and [didResolver] is the did resolver object.
  MeetingPlaceControlPlaneSDK({
    required this.didManager,
    required this.controlPlaneDid,
    required this.mediatorDid,
    required this.didResolver,
    this.controlPlaneSDKConfig = const MeetingPlaceControlPlaneSDKOptions(),
    MeetingPlaceControlPlaneSDKLogger? logger,
  }) : _logger =
           logger ??
           DefaultMeetingPlaceControlPlaneSDKLogger(
             className: className,
             sdkName: sdkName,
           ) {
    _sdkErrorHandler = SDKErrorHandler(
      logger: _logger,
      controlPlaneDid: controlPlaneDid,
    );
  }

  /// The name used to identify this class when no custom `logger` is
  /// supplied to the constructor.
  static const String className = 'MeetingPlaceControlPlaneSDK';

  /// The DID manager used to resolve and sign with the local DIDs.
  final DidManager didManager;

  /// The control plane API's DID.
  final String controlPlaneDid;

  /// The mediator's DID used when registering and creating offers.
  String mediatorDid;

  /// The SDK configuration used for retries, timeouts, and other settings.
  final MeetingPlaceControlPlaneSDKOptions controlPlaneSDKConfig;

  /// The DID resolver used to resolve DIDs encountered by the SDK.
  final DidResolver didResolver;
  final MeetingPlaceControlPlaneSDKLogger _logger;

  late final SDKErrorHandler _sdkErrorHandler;
  ControlPlaneApiClient? _controlPlaneApiClient;
  late final CommandDispatcher _dispatcher;

  Device? _device;
  Future<void>? _initializing;

  /// Whether the SDK has completed initialisation, including authentication
  /// with the control plane API.
  bool isInitialized = false;

  set device(Device? device) {
    _device = device;
  }

  /// The [Device] registered with this [MeetingPlaceControlPlaneSDK]
  /// instance, defining its deviceToken string and platformType.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.missingDevice] when the device is
  /// null.
  Device get device {
    if (_device == null) {
      throw MeetingPlaceControlPlaneSDKException(
        message: 'Device has not been set on this SDK instance.',
        code: MeetingPlaceControlPlaneSDKErrorCode.missingDevice.value,
        innerException: MissingDeviceException(),
      );
    }
    return _device!;
  }

  /// Registers an offer with the control plane.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.registerOfferMediatorNotSet] when
  /// no mediator DID is configured, or
  /// [MeetingPlaceControlPlaneSDKErrorCode.registerOfferMnemonicInUse] when
  /// [customMnemonic] is already registered. Other registration and network
  /// failures use [MeetingPlaceControlPlaneSDKErrorCode.registerOfferGeneric]
  /// and [MeetingPlaceControlPlaneSDKErrorCode.networkError], respectively.
  Future<RegisterOfferResult> registerOffer({
    required String offerName,
    required String offerDescription,
    required ContactCard contactCard,
    required Device device,
    required OfferType type,
    required PlainTextMessage oobInvitationMessage,
    required OfferTransport transport,
    DateTime? validUntil,
    int? maximumUsage,
    String? customMnemonic,
    String? mediatorDid,
    int? score,
  }) => execute(
    RegisterOfferCommand(
      offerName: offerName,
      offerDescription: offerDescription,
      contactCard: contactCard,
      device: device,
      type: type,
      oobInvitationMessage: oobInvitationMessage,
      transport: transport,
      validUntil: validUntil,
      maximumUsage: maximumUsage,
      customMnemonic: customMnemonic,
      mediatorDid: mediatorDid,
      score: score,
    ),
  );

  /// Deregisters an offer from the control plane.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.deregisterOfferFailedError],
  /// [MeetingPlaceControlPlaneSDKErrorCode.deregisterOfferGeneric], or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when deregistration
  /// fails.
  Future<DeregisterOfferResult> deregisterOffer({
    required String offerLink,
    required String mnemonic,
  }) =>
      execute(DeregisterOfferCommand(offerLink: offerLink, mnemonic: mnemonic));

  /// Finds an offer by its mnemonic phrase.
  ///
  /// The returned [FindOfferByMnemonicResult] represents success, not found,
  /// expiration, or a query-limit result.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.queryOfferOfferGeneric] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when the query fails.
  Future<FindOfferByMnemonicResult> findOfferByMnemonic({
    required String mnemonic,
  }) => execute(QueryOfferCommand(mnemonic: mnemonic));

  /// Checks whether an offer mnemonic phrase is available.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with a validation-specific
  /// [MeetingPlaceControlPlaneSDKErrorCode], or with
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when a network failure
  /// occurs.
  Future<ValidateOfferMnemonicResult> validateOfferMnemonic({
    required String mnemonic,
  }) => execute(ValidateOfferPhraseCommand(mnemonic: mnemonic));

  /// Updates the score assigned to the offers identified by [mnemonics].
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.generic] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when the update fails.
  Future<UpdateOffersScoreResult> updateOffersScore({
    required int score,
    required List<String> mnemonics,
  }) => execute(UpdateOffersScoreCommand(score: score, mnemonics: mnemonics));

  /// Accepts a registered offer.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.acceptOfferAlreadyAccepted],
  /// [MeetingPlaceControlPlaneSDKErrorCode.acceptOfferLimitExceeded],
  /// [MeetingPlaceControlPlaneSDKErrorCode.acceptOfferGeneric], or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when acceptance fails.
  Future<AcceptOfferResult> acceptOffer({
    required String mnemonic,
    required Device device,
    required String offerLink,
    required ContactCard contactCard,
    required String acceptOfferDid,
  }) => execute(
    AcceptOfferCommand(
      mnemonic: mnemonic,
      device: device,
      offerLink: offerLink,
      contactCard: contactCard,
      acceptOfferDid: acceptOfferDid,
    ),
  );

  /// Finalises an accepted offer.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.finaliseAcceptanceError],
  /// [MeetingPlaceControlPlaneSDKErrorCode.finaliseAcceptanceGeneric], or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when finalisation
  /// fails.
  Future<FinaliseAcceptanceResult> finaliseAcceptance({
    required String mnemonic,
    required String offerLink,
    required String offerPublishedDid,
    required String otherPartyAcceptOfferDid,
    required String otherPartyPermanentChannelDid,
    required Device device,
    ContactCard? contactCard,
  }) => execute(
    FinaliseAcceptanceCommand(
      mnemonic: mnemonic,
      offerLink: offerLink,
      offerPublishedDid: offerPublishedDid,
      otherPartyAcceptOfferDid: otherPartyAcceptOfferDid,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      device: device,
      contactCard: contactCard,
    ),
  );

  /// Registers a group offer with the control plane.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.registerOfferGroupMediatorNotSet]
  /// when no mediator DID is configured, or
  /// [MeetingPlaceControlPlaneSDKErrorCode.registerOfferGroupMnemonicInUse]
  /// when [customMnemonic] is already registered. Other registration and
  /// network failures use
  /// [MeetingPlaceControlPlaneSDKErrorCode.registerOfferGroupGeneric] and
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError], respectively.
  Future<RegisterOfferGroupResult> registerOfferGroup({
    required String offerName,
    required String offerDescription,
    required ContactCard contactCard,
    required Device device,
    required PlainTextMessage oobInvitationMessage,
    required String adminDid,
    DateTime? validUntil,
    int? maximumUsage,
    String? customMnemonic,
    String? mediatorDid,
    String? mediatorEndpoint,
    String? mediatorWSSEndpoint,
    String? metadata,
  }) => execute(
    RegisterOfferGroupCommand(
      offerName: offerName,
      offerDescription: offerDescription,
      contactCard: contactCard,
      device: device,
      oobInvitationMessage: oobInvitationMessage,
      adminDid: adminDid,
      validUntil: validUntil,
      maximumUsage: maximumUsage,
      customMnemonic: customMnemonic,
      mediatorDid: mediatorDid,
      mediatorEndpoint: mediatorEndpoint,
      mediatorWSSEndpoint: mediatorWSSEndpoint,
      metadata: metadata,
    ),
  );

  /// Accepts a registered group offer.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.acceptOfferGroupGeneric] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when acceptance fails.
  Future<AcceptOfferGroupResult> acceptOfferGroup({
    required String mnemonic,
    required Device device,
    required String offerLink,
    required ContactCard contactCard,
    required String acceptOfferDid,
  }) => execute(
    AcceptOfferGroupCommand(
      mnemonic: mnemonic,
      device: device,
      offerLink: offerLink,
      contactCard: contactCard,
      acceptOfferDid: acceptOfferDid,
    ),
  );

  /// Adds a member to a group.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.groupAddMemberGeneric] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when adding the member
  /// fails.
  Future<AddGroupMemberResult> addGroupMember({
    required String mnemonic,
    required String groupId,
    required String memberDid,
    required String acceptOfferDid,
    required String offerLink,
    ContactCard? contactCard,
  }) => execute(
    GroupAddMemberCommand(
      mnemonic: mnemonic,
      groupId: groupId,
      memberDid: memberDid,
      acceptOfferDid: acceptOfferDid,
      offerLink: offerLink,
      contactCard: contactCard,
    ),
  );

  /// Deregisters a member from a group.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.groupDeregisterMemberGeneric] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when deregistration
  /// fails.
  Future<DeregisterGroupMemberResult> deregisterGroupMember({
    required String groupId,
    required String memberId,
  }) => execute(
    GroupDeregisterMemberCommand(groupId: groupId, memberId: memberId),
  );

  /// Deletes a group.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.groupDeleteGeneric] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when deletion fails.
  Future<DeleteGroupResult> deleteGroup({required String groupId}) =>
      execute(GroupDeleteCommand(groupId: groupId));

  /// Notifies members of a group channel event.
  ///
  /// When [memberDid] is set, only that member is notified.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.groupNotifyChannelGeneric] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when notification
  /// fails.
  Future<NotifyGroupChannelResult> notifyGroupChannel({
    required String offerLink,
    required String groupDid,
    required String type,
    String? memberDid,
  }) => execute(
    GroupNotifyChannelCommand(
      offerLink: offerLink,
      groupDid: groupDid,
      type: type,
      memberDid: memberDid,
    ),
  );

  /// Notifies an offer publisher that their offer was accepted.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.notifyAcceptanceGeneric] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when notification
  /// fails.
  Future<NotifyAcceptanceResult> notifyAcceptance({
    required String mnemonic,
    required String acceptOfferDid,
    required String offerLink,
    required String senderInfo,
  }) => execute(
    NotifyAcceptanceCommand(
      mnemonic: mnemonic,
      acceptOfferDid: acceptOfferDid,
      offerLink: offerLink,
      senderInfo: senderInfo,
    ),
  );

  /// Notifies a group offer publisher that their offer was accepted.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.notifyAcceptanceGeneric] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when notification
  /// fails.
  Future<NotifyGroupAcceptanceResult> notifyGroupAcceptance({
    required String mnemonic,
    required String acceptOfferDid,
    required String offerLink,
    required String senderInfo,
  }) => execute(
    NotifyAcceptanceGroupCommand(
      mnemonic: mnemonic,
      acceptOfferDid: acceptOfferDid,
      offerLink: offerLink,
      senderInfo: senderInfo,
    ),
  );

  /// Notifies a channel of an event.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.notifyChannelGeneric] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when notification
  /// fails.
  Future<NotifyChannelResult> notifyChannel({
    required String notificationToken,
    required String did,
    required String type,
  }) => execute(
    NotifyChannelCommand(
      notificationToken: notificationToken,
      did: did,
      type: type,
    ),
  );

  /// Sends an outreach notification for an offer.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.notifyOutreachGeneric] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when notification
  /// fails.
  Future<NotifyOutreachResult> notifyOutreach({
    required String mnemonic,
    required String senderInfo,
  }) => execute(
    NotifyOutreachCommand(mnemonic: mnemonic, senderInfo: senderInfo),
  );

  /// Registers a device to receive notifications between two parties.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.registerNotificationGeneric] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when registration
  /// fails.
  Future<RegisterNotificationResult> registerNotification({
    required String myDid,
    required String theirDid,
    required Device device,
  }) => execute(
    RegisterNotificationCommand(
      myDid: myDid,
      theirDid: theirDid,
      device: device,
    ),
  );

  /// Deregisters a notification channel.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.deregisterNotificationGeneric] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when deregistration
  /// fails.
  Future<DeregisterNotificationResult> deregisterNotification({
    required String notificationToken,
  }) => execute(
    DeregisterNotificationCommand(notificationToken: notificationToken),
  );

  /// Fetches pending notifications for [device].
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with a
  /// [MeetingPlaceControlPlaneSDKErrorCode] of
  /// `getPendingNotificationsNotificationPayloadError`,
  /// `getPendingNotificationsGeneric`, or `networkError` when fetching fails.
  Future<GetPendingNotificationsResult> getPendingNotifications({
    required Device device,
  }) => execute(GetPendingNotificationsCommand(device: device));

  /// Deletes pending notifications for [device].
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with a
  /// [MeetingPlaceControlPlaneSDKErrorCode] of
  /// `deletePendingNotificationsDeletionFailedError`,
  /// `deletePendingNotificationsGeneric`, or `networkError` when deletion
  /// fails.
  Future<DeletePendingNotificationsResult> deletePendingNotifications({
    required Device device,
    required List<String> notificationIds,
  }) => execute(
    DeletePendingNotificationsCommand(
      device: device,
      notificationIds: notificationIds,
    ),
  );

  /// Creates a direct connection invitation through a mediator.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.createOobGeneric] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when creation fails.
  Future<CreateDirectConnectionInvitationResult>
  createDirectConnectionInvitation({
    required PlainTextMessage oobInvitationMessage,
    required String mediatorDid,
  }) => execute(
    CreateOobCommand(
      oobInvitationMessage: oobInvitationMessage,
      mediatorDid: mediatorDid,
    ),
  );

  /// Retrieves a direct connection invitation by [oobId].
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.oobNotFound] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when retrieval fails.
  Future<GetDirectConnectionInvitationResult> getDirectConnectionInvitation({
    required String oobId,
  }) => execute(GetOobCommand(oobId: oobId));

  /// Registers a device to receive push notifications.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.registerDeviceGeneric] or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when registration
  /// fails.
  Future<RegisterDeviceResult> registerDevice({
    required String deviceToken,
    required PlatformType platformType,
  }) => execute(
    RegisterDeviceCommand(deviceToken: deviceToken, platformType: platformType),
  );

  /// Gets a Matrix login token for [homeserver].
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with code
  /// [MeetingPlaceControlPlaneSDKErrorCode.matrixTokenInvalidResponse],
  /// [MeetingPlaceControlPlaneSDKErrorCode.matrixTokenGeneric], or
  /// [MeetingPlaceControlPlaneSDKErrorCode.networkError] when retrieval fails.
  Future<GetMatrixTokenResult> getMatrixToken({
    required DidManager didManager,
    required Uri homeserver,
  }) => execute(
    MatrixTokenCommand(didManager: didManager, homeserver: homeserver),
  );

  /// Uploads a did:web DID Document and its proofs.
  ///
  /// Throws a [MeetingPlaceControlPlaneSDKException] with a
  /// [MeetingPlaceControlPlaneSDKErrorCode] of
  /// `uploadDidWebDocumentAlreadyRegistered`, `uploadDidWebDocumentGeneric`,
  /// or `networkError` when upload fails.
  Future<UploadDidWebDocumentResult> uploadDidWebDocument({
    required Map<String, dynamic> didDocument,
    required DidWebProof controlProof,
    required DidWebProof proof,
  }) => execute(
    UploadDidWebDocumentCommand(
      didDocument: didDocument,
      controlProof: controlProof,
      proof: proof,
    ),
  );

  /// Private method that initialises the ControlPlaneApiClient.
  ///
  /// This is invoked by a public method within the
  /// [MeetingPlaceControlPlaneSDK].
  Future<void> _init() async {
    _dispatcher = CommandDispatcher();
    final apiClient = await ControlPlaneApiClient.init(
      controlPlaneSDK: this,
      options: ControlPlaneApiClientOptions(
        controlPlaneDid: controlPlaneDid,
        maxRetries: controlPlaneSDKConfig.maxRetries,
        maxRetriesDelay: controlPlaneSDKConfig.maxRetriesDelay,
        connectTimeout: controlPlaneSDKConfig.connectTimeout,
        receiveTimeout: controlPlaneSDKConfig.receiveTimeout,
        idleTimeout: controlPlaneSDKConfig.idleTimeout,
      ),
      didResolver: didResolver,
      logger: _logger,
    );
    // Store the client as soon as it's constructed (before authentication
    // runs) so dispose() can still close it if init fails afterwards.
    _controlPlaneApiClient = apiClient;

    _dispatcher.registerHandler(
      AuthenticateHandler(
        apiClient: apiClient,
        didManager: didManager,
        didResolver: didResolver,
        logger: _logger,
      ),
    );

    /**
     * TODO: Use dependency injection framework to avoid manual registration and
     * dependency injection
     */
    _dispatcher.registerHandler(
      RegisterDeviceHandler(mpxClient: apiClient, logger: _logger),
    );

    _dispatcher.registerHandler(
      RegisterOfferHandler(
        apiClient: apiClient,
        mediatorDid: mediatorDid,
        sdkConfig: controlPlaneSDKConfig,
        didResolver: didResolver,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(
      RegisterOfferGroupHandler(
        apiClient: apiClient,
        mediatorDid: mediatorDid,
        sdkConfig: controlPlaneSDKConfig,
        didResolver: didResolver,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(
      DeregisterOfferHandler(apiClient: apiClient, logger: _logger),
    );
    _dispatcher.registerHandler(
      ValidateOfferPhraseHandler(
        apiClient: apiClient,
        dispatcher: _dispatcher,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(
      AcceptOfferHandler(apiClient: apiClient, logger: _logger),
    );
    _dispatcher.registerHandler(
      AcceptOfferGroupHandler(apiClient: apiClient, logger: _logger),
    );
    _dispatcher.registerHandler(
      NotifyAcceptanceHandler(apiClient: apiClient, logger: _logger),
    );
    _dispatcher.registerHandler(
      NotifyAcceptanceGroupHandler(apiClient: apiClient, logger: _logger),
    );
    _dispatcher.registerHandler(
      QueryOfferHandler(
        apiClient: apiClient,
        dispatcher: _dispatcher,
        logger: _logger,
      ),
    );
    _dispatcher.registerHandler(
      FinaliseAcceptanceHandler(apiClient: apiClient, logger: _logger),
    );
    _dispatcher.registerHandler(
      RegisterNotificationHandler(apiClient: apiClient, logger: _logger),
    );
    _dispatcher.registerHandler(
      GetPendingNotificationsHandler(apiClient: apiClient, logger: _logger),
    );

    _dispatcher.registerHandler(
      NotifyChannelHandler(apiClient: apiClient, logger: _logger),
    );

    _dispatcher.registerHandler(
      DeletePendingNotificationsHandler(apiClient: apiClient, logger: _logger),
    );

    _dispatcher.registerHandler(
      GroupAddMemberHandler(apiClient: apiClient, logger: _logger),
    );

    _dispatcher.registerHandler(
      GroupDeregisterMemberHandler(apiClient: apiClient, logger: _logger),
    );

    _dispatcher.registerHandler(
      GroupDeleteHandler(apiClient: apiClient, logger: _logger),
    );

    _dispatcher.registerHandler(
      GroupNotifyChannelHandler(apiClient: apiClient, logger: _logger),
    );

    _dispatcher.registerHandler(
      DeregisterNotificationHandler(apiClient: apiClient, logger: _logger),
    );

    _dispatcher.registerHandler(
      CreateOobHandler(
        apiClient: apiClient,
        mediatorDid: mediatorDid,
        didResolver: didResolver,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(
      GetOobHandler(
        apiClient: apiClient,
        mediatorDid: mediatorDid,
        didResolver: didResolver,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(NotifyOutreachHandler(apiClient: apiClient));

    _dispatcher.registerHandler(
      MatrixTokenHandler(
        apiClient: apiClient,
        didResolver: didResolver,
        controlPlaneDid: controlPlaneDid,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(
      UploadDidWebDocumentHandler(
        didWebDocumentApi: DidWebDocumentApi(dio: apiClient.dio),
      ),
    );

    _dispatcher.registerHandler(
      UpdateOffersScoreHandler(apiClient: apiClient, logger: _logger),
    );

    await _dispatcher.dispatch<AuthenticateCommand, AuthenticateCommandOutput>(
      AuthenticateCommand(controlPlaneDid: controlPlaneDid),
    );

    isInitialized = true;
  }

  /// Executes the provided [command].
  ///
  /// This method checks first if the [MeetingPlaceControlPlaneSDK] instance
  /// has been initialised before executing the provided command using the
  /// [CommandDispatcher]. The [command] is a [DiscoveryCommand] with an
  /// overloaded generic class that extends the [DiscoveryCommand] parent
  /// class, and the result depends on the provided [DiscoveryCommand].
  Future<T> execute<T>(DiscoveryCommand<T> command) {
    final methodName = 'execute';
    _logger.info('Executing command: ${command.runtimeType}', name: methodName);

    return _withSdkExceptionHandling(() async {
      if (!isInitialized) {
        _initializing ??= _init()
            .then((_) {
              _logger.info('SDK initialization complete', name: methodName);
            })
            .catchError((Object e, StackTrace stackTrace) {
              _logger.error('SDK initialization failed: $e', name: methodName);
              _initializing = null;
              isInitialized = false;
              Error.throwWithStackTrace(e, stackTrace);
            });

        _logger.warning(
          'SDK not initialized, starting initialization...',
          name: methodName,
        );
        await _initializing;
      }
      return await _dispatcher.dispatch(command);
    });
  }

  /// A wrapper method that ensures that errors are caught and thrown on the
  /// provided function that is executed during invocation. This includes proper
  /// logging and rethrowing of caught exceptions based on
  /// [MeetingPlaceControlPlaneSDKException].
  ///
  /// **Parameters:**
  /// - [operation]: an asynchronous function to be executed.
  ///
  /// **Returns:**
  /// - An asynchronous response with generics.
  Future<T> _withSdkExceptionHandling<T>(Future<T> Function() operation) async {
    return _sdkErrorHandler.handleError(operation);
  }

  /// Releases resources held by this SDK instance, closing the underlying
  /// HTTP client. Safe to call whether or not the SDK has been initialized.
  ///
  /// Closes the HTTP client whenever one was constructed, even if
  /// initialization did not fully complete (e.g. authentication failed),
  /// since the client is created before authentication runs.
  Future<void> dispose() async {
    if (_initializing != null) {
      try {
        await _initializing;
      } catch (_) {
        // Initialization failed partway through; fall through to close
        // whatever was already constructed.
      }
    }
    _controlPlaneApiClient?.close();
  }
}
