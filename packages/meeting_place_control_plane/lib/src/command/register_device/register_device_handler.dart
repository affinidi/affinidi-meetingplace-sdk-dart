import '../../api/api_client.dart';
import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import 'register_device.dart';
import 'register_device_exception.dart';
import 'register_device_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Register Device
/// operation.
class RegisterDeviceHandler
    implements
        CommandHandler<RegisterDeviceCommand, RegisterDeviceCommandOutput> {
  /// Returns an instance of [RegisterDeviceHandler].
  ///
  /// **Parameters:**
  /// - `discoveryApiClient` - An instance of discovery api client object.
  RegisterDeviceHandler({
    required ControlPlaneApiClient mpxClient,
    ControlPlaneSDKLogger? logger,
  })  : _discoveryApiClient = mpxClient,
        _logger = logger ??
            DefaultControlPlaneSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'RegisterDeviceHandler';

  final ControlPlaneApiClient _discoveryApiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Register Device command object.
  ///
  /// **Returns:**
  /// - [RegisterDeviceCommandOutput]: The register device command output
  /// object.
  ///
  /// **Throws:**
  /// - [RegisterDeviceException]: Exception thrown by the register device
  /// operation.
  @override
  Future<RegisterDeviceCommandOutput> handle(
    RegisterDeviceCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Started registering device', name: methodName);

    try {
      final deviceTokenMappingBuilder = RegisterDeviceInputBuilder()
        ..deviceToken = command.deviceToken
        ..platformType = RegisterDeviceInputPlatformTypeEnum.valueOf(
          command.platformType.value,
        );

      _logger.info(
        '[MPX API] Calling /register-device with token: ${command.deviceToken} and platform type: ${command.platformType}',
        name: methodName,
      );
      await _discoveryApiClient.client.registerDevice(
        registerDeviceInput: deviceTokenMappingBuilder.build(),
      );

      _logger.info('Completed registering device', name: methodName);
      return RegisterDeviceCommandOutput(success: true);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to register device',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        RegisterDeviceException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
