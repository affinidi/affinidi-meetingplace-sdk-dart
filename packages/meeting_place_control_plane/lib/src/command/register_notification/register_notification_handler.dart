import '../../api/api_client.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../utils/string.dart';
import 'register_notification.dart';
import 'register_notification_exception.dart';
import 'register_notification_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Register Notification
/// operation.
class RegisterNotificationHandler
    implements
        CommandHandler<RegisterNotificationCommand,
            RegisterNotificationOutput> {
  /// Returns an instance of [RegisterNotificationHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  RegisterNotificationHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  })  : _apiClient = apiClient,
        _logger = logger ??
            DefaultControlPlaneSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'RegisterNotificationHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Register Notification command object.
  ///
  /// **Returns:**
  /// - [RegisterNotificationOutput]: The register notification command output
  /// object.
  ///
  /// **Throws:**
  /// - [RegisterNotificationException]: Exception thrown by the register
  /// notification operation.
  @override
  Future<RegisterNotificationOutput> handle(
    RegisterNotificationCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Started registering notification ', name: methodName);

    final deviceTokenMappingBuilder = RegisterNotificationInputBuilder()
      ..myDid = command.myDid
      ..theirDid = command.theirDid
      ..deviceToken = command.device.deviceToken
      ..platformType = RegisterNotificationInputPlatformTypeEnum.valueOf(
        command.device.platformType.value,
      );

    try {
      _logger.info(
        '[MPX API] Calling /register-notification for DID: ${command.myDid.topAndTail()},'
        ' device token: ${command.device.deviceToken},'
        ' platform type: ${command.device.platformType.value}',
        name: methodName,
      );
      final response = await _apiClient.client.registerNotification(
        registerNotificationInput: deviceTokenMappingBuilder.build(),
      );

      _logger.info('Completed registering notification', name: methodName);
      return RegisterNotificationOutput(
        notificationToken: response.data!.notificationToken,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to register notification',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        RegisterNotificationException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
