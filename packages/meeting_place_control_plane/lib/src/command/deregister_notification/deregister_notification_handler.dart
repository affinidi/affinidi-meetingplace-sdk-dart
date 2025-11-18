import 'dart:io';

import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import 'deregister_notification.dart';
import 'deregister_notification_error_code.dart';
import 'deregister_notification_exception.dart';
import 'deregister_notification_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Deregister
/// Notifications operation.
class DeregisterNotificationHandler
    implements
        CommandHandler<DeregisterNotificationCommand,
            DeregisterNotificationOutput> {
  /// Returns an instance of [DeregisterNotificationHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  DeregisterNotificationHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  })  : _apiClient = apiClient,
        _logger = logger ??
            DefaultControlPlaneSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'DeregisterNotificationHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Deregister notifications command object.
  ///
  /// **Returns:**
  /// - [DeregisterNotificationOutput]: The deregister notificaiton command
  /// output object.
  ///
  /// **Throws:**
  /// - [DeregisterNotificationException]: Exception thrown by the deregister
  /// notification operation.
  @override
  Future<DeregisterNotificationOutput> handle(
    DeregisterNotificationCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Started deregistering notification ', name: methodName);

    final builder = DeregisterNotificationInputBuilder()
      ..notificationToken = command.notificationToken;

    try {
      _logger.info(
        '[MPX API] Calling /deregister-notification',
        name: methodName,
      );
      await _apiClient.client.deregisterNotification(
        deregisterNotificationInput: builder.build(),
      );

      _logger.info('Completed deregistering notification', name: methodName);
      return DeregisterNotificationOutput(success: true);
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == HttpStatus.notFound) {
        _logger.warning(
          '[MPX API] deregister notification 404',
          name: methodName,
        );
        return DeregisterNotificationOutput(
          success: false,
          errorCode: DeregisterNotificationErrorCode.notFound,
        );
      }

      _logger.error(
        '[MPX API] Failed to deregister notification token',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(e, stackTrace);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to deregister notification',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        DeregisterNotificationException.generic(),
        stackTrace,
      );
    }
  }
}
