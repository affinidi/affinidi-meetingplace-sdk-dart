import 'dart:async';

import '../../api/api_client.dart';
import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../utils/string.dart';
import 'group_notify_channel.dart';
import 'group_notify_channel_exception.dart';
import 'group_notify_channel_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Group Notify
/// Channel operation.
class GroupNotifyChannelHandler
    implements
        CommandHandler<
          GroupNotifyChannelCommand,
          GroupNotifyChannelCommandOutput
        > {
  /// Returns an instance of [GroupNotifyChannelHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  GroupNotifyChannelHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  }) : _apiClient = apiClient,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );
  static const String _className = 'GroupNotifyChannelHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Group Notify Channel command object.
  ///
  /// **Returns:**
  /// - [GroupNotifyChannelCommandOutput]: The group notify channel command
  /// output object.
  ///
  /// **Throws:**
  /// - [GroupNotifyChannelException]: Exception thrown by the group notify
  /// channel operation.
  @override
  Future<GroupNotifyChannelCommandOutput> handle(
    GroupNotifyChannelCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Started notifying group channel', name: methodName);

    final builder = GroupNotifyChannelInputBuilder()
      ..offerLink = command.offerLink
      ..groupDid = command.groupDid
      ..type = command.type;

    try {
      _logger.info(
        '[MPX API] Calling /group-notify-channel for groupDid: ${command.groupDid.topAndTail()}, type: ${command.type}',
        name: methodName,
      );
      await _apiClient.client.groupNotifyChannel(
        groupNotifyChannelInput: builder.build(),
      );

      _logger.info('Completed notifying group channel', name: methodName);
      return GroupNotifyChannelCommandOutput(success: true);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed notifying group channel',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        GroupNotifyChannelException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
