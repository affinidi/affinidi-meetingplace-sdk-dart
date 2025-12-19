import 'dart:async';

import '../../api/api_client.dart';
import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../utils/string.dart';
import 'notify_channel.dart';
import 'notify_channel_exception.dart';
import 'notify_channel_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Notify Channel
/// operation.
class NotifyChannelHandler
    implements
        CommandHandler<NotifyChannelCommand, NotifyChannelCommandOutput> {
  /// Returns an instance of [NotifyChannelHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  NotifyChannelHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  }) : _apiClient = apiClient,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );
  static const String _className = 'NotifyChannelHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Notify Channel command object.
  ///
  /// **Returns:**
  /// - [NotifyChannelCommandOutput]: The notify channel command output
  /// object.
  ///
  /// **Throws:**
  /// - [NotifyChannelException]: Exception thrown by the notify channel
  /// operation.
  @override
  Future<NotifyChannelCommandOutput> handle(
    NotifyChannelCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Started notifying channel', name: methodName);

    final builder = NotifyChannelInputBuilder()
      ..notificationChannelId = command.notificationToken
      ..did = command.did
      ..type = command.type;

    try {
      _logger.info(
        '[MPX API] Calling /notify-channel for did: ${command.did.topAndTail()}, type: ${command.type}',
        name: methodName,
      );
      await _apiClient.client.notifyChannel(
        notifyChannelInput: builder.build(),
      );

      _logger.info('Completed notifying channel', name: methodName);
      return NotifyChannelCommandOutput(success: true);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed notifying channel',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        NotifyChannelException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
