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

  static const String _className = 'DiscoveryEventService';

  final ControlPlaneSDK _controlPlaneSDK;
  final ControlPlaneEventManager _discoveryEventManager;
  final MeetingPlaceCoreSDKLogger _logger;

  final List<String> _queue = [];
  final List<Object> _errors = [];

  bool _queued = false;

  Future<void> processEvents({
    required Duration debounceEvents,
    Function(List<Object> errors)? onDone,
  }) async {
    final methodName = 'processEvents';
    final processId = Uuid().v4();

    _queue.add(processId);
    _logger.info('Process id $processId added to queue', name: methodName);

    if (!_queued) {
      try {
        _queued = true;
        await Future.delayed(debounceEvents);
        _logger.info('Start processing discovery events..');
        await _process(processId: processId, onDone: onDone);
        _logger.info('Processing discovery events done..');
        _queued = false;
      } finally {
        _queued = false;
      }
    } else {
      _logger.info(
        '''Queue processing in progress. Process id $processId is going to be executed by running process''',
        name: methodName,
      );
    }
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

      _queue.remove(processId);
      _logger.info(
        'Process $processId completed and removed from queue',
        name: methodName,
      );

      if (_queue.isNotEmpty) {
        return _process(processId: _queue.first, onDone: onDone);
      }

      _onDone(onDone);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to process queue item $processId -> ${e.toString()}',
        error: e,
        stackTrace: stackTrace,
      );

      _queue.remove(processId);
      _errors.add(e);

      if (_queue.isNotEmpty) {
        return _process(processId: _queue.first, onDone: onDone);
      }

      _onDone(onDone);
    } finally {
      _queue.remove(processId);
    }

    _logger.info('Completed processing control plane events', name: methodName);
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

  void _onDone(Function(List<Object> errors)? onDone) {
    onDone?.call([..._errors]);
    _errors.clear();
  }
}
