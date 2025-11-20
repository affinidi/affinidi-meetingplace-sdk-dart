import 'dart:async';
import 'dart:collection';

import 'package:mutex/mutex.dart';

import '../../../meeting_place_mediator.dart';
import '../mediator/mediator_exception.dart';

typedef MessageId = String;

class MessageQueue {
  MessageQueue({MeetingPlaceMediatorSDKLogger? logger})
      : _logger = logger ??
            DefaultMeetingPlaceMediatorSDKLogger(
              className: _className,
              sdkName: MeetingPlaceMediatorSDK.className,
            );

  static final deleteMessageBatchSize = 100;
  static const String _className = 'MessageQueue';

  final Queue<String> _queue = Queue<String>();
  final Mutex _messageDeleteMutex = Mutex();
  final MeetingPlaceMediatorSDKLogger _logger;

  Timer? _scheduledTimer;

  void add(String messageHash) {
    final methodName = 'add';
    _logger.info('Adding message to queue', name: methodName);
    // TODO: filter by type -> epheral messages can be ignored
    // TODO: filter telemetry messages?
    _queue.add(messageHash);
  }

  void scheduleAction(
    Future<dynamic> Function(List<String>) action,
    int afterSeconds,
  ) {
    final methodName = 'scheduleAction';
    _logger.info(
      'Started scheduling delete message action in $afterSeconds seconds',
      name: methodName,
    );
    _clearSchedule();

    _scheduledTimer = Timer(Duration(seconds: afterSeconds), () async {
      if (_queue.isEmpty) {
        _logger.warning(
          'No messages in queue to delete, skipping action',
          name: methodName,
        );
        return;
      }

      try {
        await _messageDeleteMutex.acquire();

        // Log message here...
        final messagesToDelete = _queue.toList();

        // Process messages in batches of DELETE_MESSAGE_BATCH_SIZE
        for (var i = 0;
            i < messagesToDelete.length;
            i += deleteMessageBatchSize) {
          final end = (i + deleteMessageBatchSize < messagesToDelete.length)
              ? i + deleteMessageBatchSize
              : messagesToDelete.length;
          final batch = messagesToDelete.sublist(i, end);

          _logger.info(
            'Deleting batch of ${batch.length} messages from server '
            '(${i + 1}-$end of ${messagesToDelete.length})',
            name: methodName,
          );

          /**
           * TODO: handle errors from mediator? Currently we delete
           * all expected messages from queue but sometimes it fails only for
           * some messages.
           */
          await action(batch);
          _queue.removeWhere(batch.contains);
        }
      } catch (e, stackTrace) {
        _logger.error(
          'Message queue exception: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
          name: methodName,
        );
        Error.throwWithStackTrace(
          MediatorException.sendMessageError(innerException: e),
          stackTrace,
        );
      } finally {
        _logger.info(
          'Completed deleting messages from queue',
          name: methodName,
        );
        _messageDeleteMutex.release();
      }
    });
    _logger.info(
      'Completed scheduling delete message action in $afterSeconds seconds',
      name: methodName,
    );
  }

  void _clearSchedule() {
    final methodName = '_clearSchedule';
    _logger.info('Clearing scheduled timer', name: methodName);
    if (_scheduledTimer != null) {
      _scheduledTimer!.cancel();
      _scheduledTimer = null;
    }
  }
}
