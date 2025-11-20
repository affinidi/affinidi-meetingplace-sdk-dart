import 'dart:async';
import 'dart:convert';

import '../../api/api_client.dart';
import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../core/discover_notification_type.dart';
import '../../core/event/channel_activity.dart';
import '../../core/event/discovery_event.dart';
import '../../core/event/discovery_event_type.dart';
import '../../core/event/group_membership_finalised.dart';
import '../../core/event/invitation_accept.dart';
import '../../core/event/invitation_group_accept.dart';
import '../../core/event/invitation_outreach.dart';
import '../../core/event/offer_finalised.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../finalise_acceptance/finalise_acceptance_handler.dart'
    show FinaliseAcceptanceHandler;
import 'get_pending_notifications.dart';
import 'get_pending_notifications_exception.dart';
import 'get_pending_notifications_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Get Pending
/// Notifications operation.
class GetPendingNotificationsHandler
    implements
        CommandHandler<GetPendingNotificationsCommand,
            GetPendingNotificationsCommandOutput> {
  /// Returns an instance of [FinaliseAcceptanceHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  GetPendingNotificationsHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  })  : _apiClient = apiClient,
        _logger = logger ??
            DefaultControlPlaneSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'GetPendingNotificationsHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Get Pending Notification command object.
  ///
  /// **Returns:**
  /// - [GetPendingNotificationsCommandOutput]: The get pending notification
  ///  command output object.
  ///
  /// **Throws:**
  /// - [GetPendingNotificationsException]: Exception thrown by the get pending
  /// notification operation.
  @override
  Future<GetPendingNotificationsCommandOutput> handle(
    GetPendingNotificationsCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Started getting pending notifications', name: methodName);

    final builder = GetPendingNotificationsInputBuilder()
      ..platformType = GetPendingNotificationsInputPlatformTypeEnum.valueOf(
        command.device.platformType.value,
      )
      ..deviceToken = command.device.deviceToken;

    try {
      _logger.info(
        '[MPX API] Calling /notifications for device platform: '
        '${command.device.platformType.value}',
        name: methodName,
      );
      final response = (await _apiClient.client.getPendingNotifications(
        getPendingNotificationsInput: builder.build(),
      ))
          .data;

      final events = response!.notifications!.map(_parseNotification).toList();
      final processableEvents = _filterProcessableEvents(events);

      _logger.info(
        'Completed getting pending notifications. '
        'Total events: ${events.length}, '
        'Processable events: ${processableEvents.length}',
        name: methodName,
      );
      return GetPendingNotificationsCommandOutput(events: processableEvents);
    } on GetPendingNotificationsException {
      _logger.warning('Get pending notifications exception');
      rethrow;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get pending notifications: ',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        GetPendingNotificationsException.generic(innerException: e),
        stackTrace,
      );
    }
  }

  DiscoveryEvent _parseNotification(
    GetPendingNotificationsOKNotificationsInner notification,
  ) {
    final methodName = 'GetPendingNotificationsHandler._parseNotification';
    _logger.info(
      'Started parsing notification with ID: ${notification.id}',
      name: methodName,
    );

    final notificationPayload = notification.payload;
    final notificationType = notification.type;

    if (notificationPayload == null || notificationType == null) {
      _logger.error(
        'Notification payload or type is null for notification ID: '
        '${notification.id}',
        name: methodName,
      );
      throw GetPendingNotificationsException.notificationPayloadError();
    }

    final payload = jsonDecode(notificationPayload) as Map<String, dynamic>;
    final (eventType, eventData) = _parseData(payload, type: notificationType);

    _logger.info(
      'Completed parsing notification for event Type: ${eventType.name}',
      name: methodName,
    );
    return DiscoveryEvent(
      id: notification.id!,
      type: eventType,
      data: eventData,
      status: DiscoveryEventStatus.New,
    );
  }

  List<DiscoveryEvent> _filterProcessableEvents(List<DiscoveryEvent> events) {
    // process all events except chat activity

    final processedDids = <String>[];
    final processableEvents = <DiscoveryEvent>[];

    for (final event in events) {
      final eventData = event.data;

      if (eventData is! ChannelActivity) {
        processableEvents.add(event);
        continue;
      }

      if (eventData.type != 'chat-activity') {
        processableEvents.add(event);
        processedDids.contains(eventData.did);
        continue;
      }

      if (processedDids.contains(eventData.did)) {
        // TODO: add logic here
        // mark notification as deleted / read
        // what do we do here? Do we delete the messages?
        continue;
      }

      processableEvents.add(event);
    }

    return processableEvents;
  }

  (ControlPlaneEventType type, dynamic data) _parseData(
    Map<String, dynamic> payload, {
    required String type,
  }) {
    final payloadData = payload['data'] as Map<String, dynamic>;

    if (!DiscoveryNotificationType.values.any((t) => t.name == type)) {
      return (ControlPlaneEventType.Unknown, <void, void>{});
    }

    switch (DiscoveryNotificationType.values.byName(type)) {
      case DiscoveryNotificationType.InvitationAccept:
        return (
          ControlPlaneEventType.InvitationAccept,
          InvitationAccept.fromJson(payloadData),
        );
      case DiscoveryNotificationType.InvitationGroupAccept:
        return (
          ControlPlaneEventType.InvitationGroupAccept,
          InvitationGroupAccept.fromJson(payloadData),
        );
      case DiscoveryNotificationType.GroupMembershipFinalised:
        return (
          ControlPlaneEventType.GroupMembershipFinalised,
          GroupMembershipFinalised.fromJson(payloadData),
        );
      case DiscoveryNotificationType.OfferFinalised:
        return (
          ControlPlaneEventType.OfferFinalised,
          OfferFinalised.fromJson(payloadData),
        );
      case DiscoveryNotificationType.InvitationOutreach:
        return (
          ControlPlaneEventType.InvitationOutreach,
          InvitationOutreach.fromJson(payloadData),
        );
      case DiscoveryNotificationType.ChannelActivity:
        return (
          ControlPlaneEventType.ChannelActivity,
          ChannelActivity.fromJson(payloadData),
        );
    }
  }
}
