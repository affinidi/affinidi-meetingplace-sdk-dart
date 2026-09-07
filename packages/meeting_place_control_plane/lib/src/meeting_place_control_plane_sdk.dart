import 'dart:async';

import 'package:ssi/ssi.dart';

import 'api/control_plane_api_client.dart';
import 'api/control_plane_api_client_options.dart';
import 'api/did_web_document_api.dart';
import 'command/accept_offer/accept_offer_handler.dart';
import 'command/accept_offer_group/accept_offer_group_handler.dart';
import 'command/authenticate/authenticate.dart';
import 'command/authenticate/authenticate_handler.dart';
import 'command/authenticate/authenticate_output.dart';
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

  /// Sets the [device] variable of the [MeetingPlaceControlPlaneSDK]
  /// instance.
  ///
  /// The given [device] is a [Device] object that defines the deviceToken
  /// string and its platformType.
  set device(Device? device) {
    _device = device;
  }

  /// Returns the [device] variable of the [MeetingPlaceControlPlaneSDK]
  /// instance, a [Device] object that defines the deviceToken string and its
  /// platformType.
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
