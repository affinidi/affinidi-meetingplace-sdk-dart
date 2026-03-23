import 'dart:async';

import '../../api/api_client.dart';
import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../utils/string.dart';
import 'notify_channel_group.dart';
import 'notify_channel_group_exception.dart';
import 'notify_channel_group_output.dart';

/// A concrete implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for the Notify
/// Channel Group operation.
class NotifyChannelGroupHandler
    implements
        CommandHandler<
          NotifyChannelGroupCommand,
          NotifyChannelGroupCommandOutput
        > {
  NotifyChannelGroupHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  }) : _apiClient = apiClient,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );

  static const String _className = 'NotifyChannelGroupHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  @override
  Future<NotifyChannelGroupCommandOutput> handle(
    NotifyChannelGroupCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Started notifying channel group', name: methodName);

    final builder = NotifyChannelGroupInputBuilder()
      ..groupId = command.groupId
      ..type = command.type;

    try {
      _logger.info(
        '[MPX API] Calling /notify-channel-group for groupId: ${command.groupId.topAndTail()}, type: ${command.type}',
        name: methodName,
      );
      final response = await _apiClient.client.notifyChannelGroup(
        notifyChannelGroupInput: builder.build(),
      );

      _logger.info('Completed notifying channel group', name: methodName);
      return NotifyChannelGroupCommandOutput(
        success: true,
        notifiedCount: response.data?.notifiedCount ?? 0,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed notifying channel group',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        NotifyChannelGroupException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
