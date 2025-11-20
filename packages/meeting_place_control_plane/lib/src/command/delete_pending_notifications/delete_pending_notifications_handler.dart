import 'dart:async';

import 'package:built_collection/built_collection.dart';

import '../../api/api_client.dart';
import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../core/device/device.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import 'delete_pending_notifications.dart';
import 'delete_pending_notifications_exception.dart';
import 'delete_pending_notifications_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Delete Pending
/// Notifications operation.
class DeletePendingNotificationsHandler
    implements
        CommandHandler<DeletePendingNotificationsCommand,
            DeletePendingNotificationsCommandOutput> {
  /// Returns an instance of [DeletePendingNotificationsHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  DeletePendingNotificationsHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  })  : _apiClient = apiClient,
        _logger = logger ??
            DefaultControlPlaneSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'DeletePendingNotificationsHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Accept offer command object.
  ///
  /// **Returns:**
  /// - [DeletePendingNotificationsCommandOutput]: The delete pending
  /// notificaiton command output object.
  ///
  /// **Throws:**
  /// - [DeletePendingNotificationsException]: Exception thrown by the delete
  /// pending notification handler.
  @override
  Future<DeletePendingNotificationsCommandOutput> handle(
    DeletePendingNotificationsCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Started deleting pending notifications', name: methodName);

    try {
      final deletedNotificationIds = await _delete(
        device: command.device,
        notificationIds: command.notificationIds,
        deletedNotificationIds: [],
      );
      _logger.info(
        'Completed deleting pending notifications: $deletedNotificationIds',
        name: methodName,
      );
      return DeletePendingNotificationsCommandOutput(
        deletedNotificationIds: deletedNotificationIds,
      );
    } on DeletePendingNotificationsException {
      rethrow;
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        DeletePendingNotificationsException.generic(innerException: e),
        stackTrace,
      );
    }
  }

  /// Private method that deletes the pending notifications.
  ///
  /// **Parameters:**
  /// - [device]: The device object.
  /// - [notificationIds]: The list of notification ids to be deleted.
  /// - [deletedNotificationIds]: The list of deleted notification ids.
  ///
  /// **Returns:**
  /// - [List<String>]: List of notification ids that are deleted after the
  /// execution of the operation.
  Future<List<String>> _delete({
    required Device device,
    required List<String> notificationIds,
    required List<String> deletedNotificationIds,
  }) async {
    final methodName = '_delete';
    _logger.info(
      'Started to delete notifications: $notificationIds',
      name: methodName,
    );

    try {
      final builder = DeletePendingNotificationsInputBuilder()
        ..platformType =
            DeletePendingNotificationsInputPlatformTypeEnum.valueOf(
          device.platformType.value,
        )
        ..deviceToken = device.deviceToken
        ..notificationIds = ListBuilder(notificationIds);

      _logger.info(
        '[MPX API] Calling delete /notifications for notificationIds: $notificationIds',
        name: methodName,
      );

      final response = await _apiClient.client.deletePendingNotifications(
        deletePendingNotificationsInput: builder.build(),
      );

      final deletedIds = response.data!.deletedIds!;
      _logger.info('Deleted ${deletedIds.length} notifications');

      for (final deletedId in deletedIds) {
        notificationIds.remove(deletedId);
      }

      final allDeletedNotificationIds = <String>[
        ...deletedNotificationIds,
        ...deletedIds,
      ];

      if (notificationIds.isNotEmpty && deletedIds.isNotEmpty) {
        _logger.info(
          'Continuing to delete remaining notifications: $notificationIds ...',
          name: methodName,
        );
        return _delete(
          device: device,
          notificationIds: notificationIds,
          deletedNotificationIds: allDeletedNotificationIds,
        );
      }

      return allDeletedNotificationIds;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to delete pending notifications',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        DeletePendingNotificationsException.deletionFailedError(
          innerException: e,
          deletedNotificationIds: deletedNotificationIds,
        ),
        stackTrace,
      );
    }
  }
}
