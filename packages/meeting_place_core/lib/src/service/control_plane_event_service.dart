import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import '../event_handler/control_plane_event_handler_manager.dart';
import '../loggers/default_meeting_place_core_sdk_logger.dart';
import '../loggers/meeting_place_core_sdk_logger.dart';

class ControlPlaneEventService {
  ControlPlaneEventService({
    required ControlPlaneSDK controlPlaneSDK,
    required ControlPlaneEventManager discoveryEventManager,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _controlPlaneSDK = controlPlaneSDK,
       _discoveryEventManager = discoveryEventManager,
       _logger =
           logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className);

  static const String _className = 'ControlPlaneEventService';

  final ControlPlaneSDK _controlPlaneSDK;
  final ControlPlaneEventManager _discoveryEventManager;
  final MeetingPlaceCoreSDKLogger _logger;

  final List<String> _queue = [];
  final List<Object> _errors = [];

  Future<void>? _processing;

  Future<void> processEvents({
    required Duration debounceEvents,
    Function(List<Object> errors)? onDone,
  }) async {
    final methodName = 'processEvents';
    final processId = Uuid().v4();

    _queue.add(processId);
    _logger.info('Process id $processId added to queue', name: methodName);

    _processing = (_processing ?? Future.value()).then((_) async {
      await Future.delayed(debounceEvents);
      _logger.info('Start processing discovery events..');
      await _process(processId: processId, onDone: onDone);
      _logger.info('Processing discovery events done..');
    });

    await _processing;
  }

  Future<void> _process({
    required String processId,
    Function(List<Object> errors)? onDone,
  }) async {
    final methodName = '_process';
    _logger.info(
      'Processing process id $processId from queue',
      name: methodName,
    );

    try {
      final result = await _controlPlaneSDK.execute(
        GetPendingNotificationsCommand(device: _controlPlaneSDK.device),
      );

      if (result.events.isEmpty) {
        _queue.clear();
        _logger.info(
          'Notification check complete: no pending items detected, queue successfully cleared.',
          name: methodName,
        );
        _onDone(onDone);
        return;
      }

      final processedEvents = await _discoveryEventManager.handleEventsBatch(
        result.events,
      );

      await _controlPlaneSDK.execute(
        DeletePendingNotificationsCommand(
          notificationIds: processedEvents.map((e) => e.id).toList(),
          device: _controlPlaneSDK.device,
        ),
      );

      _logger.info(
        'Process $processId completed and removed from queue',
        name: methodName,
      );

      return _next(processId, onDone);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to process queue item $processId -> ${e.toString()}',
        error: e,
        stackTrace: stackTrace,
      );

      _queue.remove(processId);
      _errors.add(e);

      return _next(_queue.first, onDone);
    } finally {
      _queue.remove(processId);
    }
  }

  Future<List<String>> deleteAll() async {
    final result = await _controlPlaneSDK.execute(
      GetPendingNotificationsCommand(device: _controlPlaneSDK.device),
    );

    if (result.events.isEmpty) {
      return [];
    }

    final deleteResult = await _controlPlaneSDK.execute(
      DeletePendingNotificationsCommand(
        notificationIds: result.events.map((e) => e.id).toList(),
        device: _controlPlaneSDK.device,
      ),
    );

    return deleteResult.deletedNotificationIds;
  }

  Future<void> _next(
    String processId,
    Function(List<Object> errors)? onDone,
  ) async {
    if (_queue.isEmpty) {
      _logger.info('Completed processing control plane events', name: '_next');
      return _onDone(onDone);
    }

    return _process(processId: processId, onDone: onDone);
  }

  void _onDone(Function(List<Object> errors)? onDone) {
    onDone?.call([..._errors]);
    _errors.clear();
  }
}
