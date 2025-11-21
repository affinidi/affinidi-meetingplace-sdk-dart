import 'dart:async';
import 'dart:collection';

import 'package:didcomm/didcomm.dart';
import 'package:mutex/mutex.dart';

import '../../../meeting_place_mediator.dart';
import '../../utils/string.dart';
import '../mediator/mediator_exception.dart';

typedef MessageId = String;

class MessageQueue {
  MessageQueue({
    required MediatorClient client,
    MeetingPlaceMediatorSDKLogger? logger,
  })  : _client = client,
        _logger = logger ??
            DefaultMeetingPlaceMediatorSDKLogger(
              className: _className,
              sdkName: MeetingPlaceMediatorSDK.className,
            );

  static final deleteMessageBatchSize = 100;
  static const String _className = 'MessageQueue';

  final MediatorClient _client;
  final Queue<String> _queue = Queue<String>();

  final Mutex _messageDeleteMutex = Mutex();
  final MeetingPlaceMediatorSDKLogger _logger;

  Timer? _scheduledTimer;

  void add(String messageHash) {
    _queue.add(messageHash);
    _logger.info('Message hash $messageHash queued', name: 'add');
  }

  void scheduleDeletion(String messageHash, {required Duration? delay}) {
    if (delay == null) {
      _logger.info(
        'Deleting message $messageHash immediately',
        name: 'scheduleDeletion',
      );

      unawaited(_client.deleteMessages(messageIds: [messageHash]).then((_) =>
          _logger.info('Message $messageHash deleted immediately',
              name: 'scheduleDeletion')));

      return;
    }

    add(messageHash);
    scheduleAction((List<String> hashes) async {
      _logger.info(
        '''Deleting ${hashes.length} message(s) for session ${_client.didKeyId.topAndTail()}...''',
        name: '_scheduleForDeletion',
      );

      await _client.deleteMessages(messageIds: hashes);
    }, delay);
  }

  void scheduleAction(
    Future<dynamic> Function(List<String>) action,
    Duration delay,
  ) {
    final methodName = 'scheduleAction';
    _logger.info(
      '''Started scheduling delete message action in
      ${delay.inMilliseconds} milliseconds''',
      name: methodName,
    );
    _clearSchedule();

    _scheduledTimer = Timer(delay, () async {
      if (_queue.isEmpty) {
        _logger.warning(
          'No messages in queue to delete, skipping action',
          name: methodName,
        );
        return;
      }

      try {
        await _messageDeleteMutex.acquire();

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
            'Deleting batch of ${batch.length} messages from server (${i + 1}-$end of ${messagesToDelete.length})',
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

    _logger.info('Message deletion scheduled', name: methodName);
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
