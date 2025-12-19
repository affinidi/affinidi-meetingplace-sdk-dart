import 'dart:async';

import '../../api/api_client.dart';
import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../utils/string.dart';
import 'group_deregister_member_exception.dart';
import 'group_send_message.dart';
import 'group_send_message.output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Group Send
/// Message operation.
class GroupSendMessageHandler
    implements
        CommandHandler<GroupSendMessageCommand, GroupSendMessageCommandOutput> {
  /// Returns an instance of [GroupSendMessageHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  GroupSendMessageHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  }) : _apiClient = apiClient,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );
  static const String _className = 'GroupSendMessageHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Group send message command object.
  ///
  /// **Returns:**
  /// - [GroupSendMessageCommandOutput]: The group send message command output
  /// object.
  ///
  /// **Throws:**
  /// - [GroupSendMessageException]: Exception thrown by the group send message
  /// operation.
  @override
  Future<GroupSendMessageCommandOutput> handle(
    GroupSendMessageCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Started sending group message ', name: methodName);

    final builder = GroupSendMessageBuilder()
      ..offerLink = command.offerLink
      ..fromDid = command.fromDid
      ..groupDid = command.groupDid
      ..payload = command.messageBase64
      ..notify = command.notify
      ..incSeqNo = command.increaseSequenceNumber
      ..ephemeral = command.ephemeral
      ..expiresTime = command.forwardExpiryInSeconds != null
          ? DateTime.now()
                .toUtc()
                .add(Duration(seconds: command.forwardExpiryInSeconds!))
                .toIso8601String()
          : null;

    try {
      _logger.info(
        '[MPX API] Calling /group-send-message from:'
        ' ${command.fromDid.topAndTail()} to'
        ' group: ${command.groupDid.topAndTail()}',
        name: methodName,
      );
      await _apiClient.client.groupSendMessage(
        groupSendMessage: builder.build(),
      );

      _logger.info('Completed sending group message', name: methodName);
      return GroupSendMessageCommandOutput(success: true);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to send group message',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        GroupSendMessageException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
