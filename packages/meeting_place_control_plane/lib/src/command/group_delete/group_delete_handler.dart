import 'dart:async';
import 'dart:io';

import '../../api/api_client.dart';
import 'package:dio/dio.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import 'group_delete.dart';
import 'group_delete_exception.dart';
import 'group_delete_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Group Delete
/// operation.
class GroupDeleteHandler
    implements CommandHandler<GroupDeleteCommand, GroupDeleteCommandOutput> {
  /// Returns an instance of [GroupDeleteHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  GroupDeleteHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  })  : _apiClient = apiClient,
        _logger = logger ??
            DefaultControlPlaneSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'GroupDeleteHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Group Delete command object.
  ///
  /// **Returns:**
  /// - [GroupDeleteCommandOutput]: The group delete command output object.
  ///
  /// **Throws:**
  /// - [GroupDeleteException]: Exception thrown by the group delete operation.
  @override
  Future<GroupDeleteCommandOutput> handle(GroupDeleteCommand command) async {
    final methodName = 'handle';
    _logger.info('Started handling group delete', name: methodName);

    final builder = GroupDeleteInputBuilder()
      ..groupId = command.groupId
      ..messageToRelay = command.messageBase64;

    try {
      _logger.info(
        '[MPX API] Calling /group-delete for groupId: ${command.groupId}',
        name: methodName,
      );
      await _apiClient.client.groupDelete(
        groupDeleteInput: builder.build(),
      );

      _logger.info('Completed handling group delete', name: methodName);
      return GroupDeleteCommandOutput(success: true);
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == HttpStatus.gone) {
        _logger.warning(
          '[MPX API] Response has status code ${e.response?.statusCode} - assume everything is okay as group was already deleted',
          name: methodName,
        );
        return GroupDeleteCommandOutput(success: true);
      }

      _logger.error('[MPX API] Failed to delete group', name: methodName);
      Error.throwWithStackTrace(e, stackTrace);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to delete group',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        GroupDeleteException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
