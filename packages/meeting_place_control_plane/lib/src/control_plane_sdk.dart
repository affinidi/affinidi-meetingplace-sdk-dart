import 'dart:async';

import 'api/control_plane_api_client.dart';
import 'api/control_plane_api_client_options.dart';
import 'command/create_oob/create_oob_handler.dart';
import 'command/deregister_notification/deregister_notification_handler.dart';
import 'command/get_oob/get_oob_handler.dart';
import 'command/group_delete/group_delete_handler.dart';
import 'command/group_member_deregister/group_deregister_member_handler.dart';
import 'package:ssi/ssi.dart';

import 'command/accept_offer/accept_offer_handler.dart';
import 'command/accept_offer_group/accept_offer_group_handler.dart';
import 'command/authenticate/authenticate_handler.dart';
import 'command/authenticate/authenticate_output.dart';
import 'command/authenticate/authenticate.dart';
import 'command/delete_pending_notifications/delete_pending_notifications_handler.dart';
import 'command/deregister_offer/deregister_offer_handler.dart';
import 'command/notify_outreach/notify_outreach_handler.dart';
import 'command/validate_offer_phrase/validate_offer_phrase_handler.dart';
import 'command/finalise_acceptance/finalise_acceptance_handler.dart';
import 'command/get_pending_notifications/get_pending_notifications_handler.dart';
import 'command/group_add_member/group_add_member_handler.dart';
import 'command/group_send_message/group_send_message_handler.dart';
import 'command/notify_acceptance/notify_acceptance_handler.dart';
import 'command/notify_acceptance_group/notify_acceptance_handler.dart';
import 'command/notify_channel/notify_channel_handler.dart';
import 'command/query_offer/query_offer_handler.dart';
import 'command/register_device/register_device_handler.dart';
import 'command/register_notification/register_notification_handler.dart';
import 'command/register_offer/register_offer_handler.dart';
import 'command/register_offer_group/register_offer_group_handler.dart';
import 'core/command/command.dart';
import 'core/command/command_dispatcher.dart';
import 'control_plane_sdk_options.dart';
import 'core/device/device.dart';
import 'control_plane_sdk_exception.dart';
import 'loggers/default_control_plane_sdk_logger.dart';
import 'loggers/control_plane_sdk_logger.dart';
import 'core/sdk_error_handler.dart';
import 'constants/sdk_constants.dart';

class MissingDeviceException implements Exception {}

/// The **ControlPlaneSDK** provides the libraries to enable the discovery of other
/// participants to establish a connection and communicate securely.
///
/// It enables participants to publish a connection offer to allow other
/// participants to communicate directly or through group chat.
/// Through discovery, organisations and AI agents can publish their
/// connection offers to allow users to connect and start using their services.
class ControlPlaneSDK {
  /// The constructor used to create an instance of **ControlPlaneSDK**.
  ///
  /// **Parameters:**
  /// - [didManager]: The did manager object.
  /// - [controlPlaneDid]: The control plane API DID string.
  /// - [mediatorDid]: The mediator DID string.
  /// - [controlPlaneSDKConfig]: The control plane SDK configuration object.
  /// - [didResolver]: The did resolver object.
  ///
  /// **Returns:**
  /// - An instance of [ControlPlaneSDK].
  ControlPlaneSDK({
    required this.didManager,
    required this.controlPlaneDid,
    required this.mediatorDid,
    required this.didResolver,
    this.controlPlaneSDKConfig = const ControlPlaneSDKOptions(),
    ControlPlaneSDKLogger? logger,
  }) : _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: className,
             sdkName: sdkName,
           ) {
    _sdkErrorHandler = SDKErrorHandler(
      logger: _logger,
      controlPlaneDid: controlPlaneDid,
    );
  }

  static const String className = 'ControlPlaneSDK';

  final DidManager didManager;
  final String controlPlaneDid;
  final String mediatorDid;
  final ControlPlaneSDKOptions controlPlaneSDKConfig;
  final DidResolver didResolver;
  final ControlPlaneSDKLogger _logger;

  late final SDKErrorHandler _sdkErrorHandler;
  late final ControlPlaneApiClient _controlPlaneApiClient;
  late final CommandDispatcher _dispatcher;

  Device? _device;
  Future<void>? _initializing;
  bool isInitialized = false;

  /// Setter method that sets the value of [Device] variable of the [ControlPlaneSDK] instance.
  ///
  /// **Parameters:**
  /// - [device]: A [Device] object that defines the deviceToken string and its
  /// platformType.
  set device(Device? device) {
    _device = device;
  }

  /// Setter method to set the value of [mediatorDid] variable of the [ControlPlaneSDK] instance.
  ///
  /// **Parameters:**
  /// - [mediatorDid]: The mediator DID string.
  set mediatorDid(String mediatorDid) {
    this.mediatorDid = mediatorDid;
  }

  /// Getter method to fetch the value of [device] variable of the [ControlPlaneSDK] instance.
  ///
  /// **Returns:**
  /// - [device]: A [Device] object that defines the deviceToken string and its
  /// platformType.
  ///
  /// **Throws:**
  /// - [MissingDeviceException]: An exception thrown when device is null.
  Device get device {
    final methodName = 'device';

    if (_device == null) {
      _logger.error(
        'Device not set, SDK did not receive FCM token',
        name: methodName,
      );
      throw MissingDeviceException();
    }
    return _device!;
  }

  /// Private method that initialises the DiscoveryApiClient.
  /// This is invoked by a public method within the [DiscoverSDK].
  Future<void> _init() async {
    _controlPlaneApiClient = await ControlPlaneApiClient.init(
      controlPlaneSDK: this,
      options: ControlPlaneApiClientOptions(
        controlPlaneDid: controlPlaneDid,
        maxRetries: controlPlaneSDKConfig.maxRetries,
        maxRetriesDelay: controlPlaneSDKConfig.maxRetriesDelay,
        connectTimeout: controlPlaneSDKConfig.connectTimeout,
        receiveTimeout: controlPlaneSDKConfig.receiveTimeout,
      ),
      didResolver: didResolver,
      logger: _logger,
    );

    _dispatcher = CommandDispatcher();
    _dispatcher.registerHandler(
      AuthenticateHandler(
        apiClient: _controlPlaneApiClient,
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
      RegisterDeviceHandler(mpxClient: _controlPlaneApiClient, logger: _logger),
    );

    _dispatcher.registerHandler(
      RegisterOfferHandler(
        apiClient: _controlPlaneApiClient,
        mediatorDid: mediatorDid,
        sdkConfig: controlPlaneSDKConfig,
        didResolver: didResolver,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(
      RegisterOfferGroupHandler(
        apiClient: _controlPlaneApiClient,
        mediatorDid: mediatorDid,
        sdkConfig: controlPlaneSDKConfig,
        didResolver: didResolver,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(
      DeregisterOfferHandler(
        apiClient: _controlPlaneApiClient,
        logger: _logger,
      ),
    );
    _dispatcher.registerHandler(
      ValidateOfferPhraseHandler(
        apiClient: _controlPlaneApiClient,
        dispatcher: _dispatcher,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(
      AcceptOfferHandler(apiClient: _controlPlaneApiClient, logger: _logger),
    );
    _dispatcher.registerHandler(
      AcceptOfferGroupHandler(
        apiClient: _controlPlaneApiClient,
        logger: _logger,
      ),
    );
    _dispatcher.registerHandler(
      NotifyAcceptanceHandler(
        apiClient: _controlPlaneApiClient,
        logger: _logger,
      ),
    );
    _dispatcher.registerHandler(
      NotifyAcceptanceGroupHandler(
        apiClient: _controlPlaneApiClient,
        logger: _logger,
      ),
    );
    _dispatcher.registerHandler(
      QueryOfferHandler(
        apiClient: _controlPlaneApiClient,
        dispatcher: _dispatcher,
        logger: _logger,
      ),
    );
    _dispatcher.registerHandler(
      FinaliseAcceptanceHandler(
        apiClient: _controlPlaneApiClient,
        logger: _logger,
      ),
    );
    _dispatcher.registerHandler(
      RegisterNotificationHandler(
        apiClient: _controlPlaneApiClient,
        logger: _logger,
      ),
    );
    _dispatcher.registerHandler(
      GetPendingNotificationsHandler(
        apiClient: _controlPlaneApiClient,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(
      NotifyChannelHandler(apiClient: _controlPlaneApiClient, logger: _logger),
    );

    _dispatcher.registerHandler(
      DeletePendingNotificationsHandler(
        apiClient: _controlPlaneApiClient,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(
      GroupAddMemberHandler(apiClient: _controlPlaneApiClient, logger: _logger),
    );
    _dispatcher.registerHandler(
      GroupSendMessageHandler(
        apiClient: _controlPlaneApiClient,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(
      GroupDeregisterMemberHandler(
        apiClient: _controlPlaneApiClient,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(
      GroupDeleteHandler(apiClient: _controlPlaneApiClient, logger: _logger),
    );

    _dispatcher.registerHandler(
      DeregisterNotificationHandler(
        apiClient: _controlPlaneApiClient,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(
      CreateOobHandler(
        apiClient: _controlPlaneApiClient,
        mediatorDid: mediatorDid,
        didResolver: didResolver,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(
      GetOobHandler(
        apiClient: _controlPlaneApiClient,
        mediatorDid: mediatorDid,
        didResolver: didResolver,
        logger: _logger,
      ),
    );

    _dispatcher.registerHandler(
      NotifyOutreachHandler(apiClient: _controlPlaneApiClient),
    );

    await _dispatcher.dispatch<AuthenticateCommand, AuthenticateCommandOutput>(
      AuthenticateCommand(controlPlaneDid: controlPlaneDid),
    );

    isInitialized = true;
  }

  /// The method that executes a provided [DiscoveryCommand].
  ///
  /// This method checks first if the [ControlPlaneSDK] instance has been
  /// initialised before executing the provided command using the
  /// [CommandDispatcher].
  ///
  /// **Parameters:**
  /// - [DiscoveryCommand<T>]: The ControlPlaneSDK command with an overloaded
  /// generic class that extends the [DiscoveryCommand] parent class.
  ///
  /// **Returns:**
  /// - A discovery command result depending on the provided [DiscoverCommand].
  Future<T> execute<T>(DiscoveryCommand<T> command) {
    final methodName = 'execute';
    _logger.info('Executing command: ${command.runtimeType}', name: methodName);

    return _withSdkExceptionHandling(() async {
      if (!isInitialized) {
        // Ensure only one initialization happens, even with concurrent calls
        _initializing ??= _init()
            .then((_) {
              _logger.info('SDK initialization complete', name: methodName);
            })
            .catchError((e, stackTrace) {
              _logger.error('SDK initialization failed: $e', name: methodName);
              // Reset to allow retry on next execute call
              _initializing = null;
              // Clean up partial state
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
  /// [ControlPlaneSDKException].
  ///
  /// **Parameters:**
  /// - [operation]: an asynchronous function to be executed.
  ///
  /// **Returns:**
  /// - An asynchronous response with generics.
  Future<T> _withSdkExceptionHandling<T>(Future<T> Function() operation) async {
    return _sdkErrorHandler.handleError(operation);
  }
}
