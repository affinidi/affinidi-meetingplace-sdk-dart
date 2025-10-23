import 'dart:async';
import 'dart:collection';

import 'package:didcomm/didcomm.dart';
import 'package:mutex/mutex.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../constants/sdk_constants.dart';
import '../../loggers/default_meeting_place_mediator_sdk_logger.dart';
import '../../loggers/meeting_place_mediator_sdk_logger.dart';
import '../mediator/mediator_exception.dart';

/// Represents a message item within a queue.
///
/// **Parameters:**
/// - [message]: The [PlainTextMessage] that was sent to a queue.
/// - [senderDidManager]: The [DidManager] instance used for authentication with the mediator
/// and contains the identity credentials needed for the session.
/// - [mediatorDid]: Optional mediator DID to authenticate against.
/// If not provided, the SDK instance’s default mediator DID will be used.
/// - [next]: The DID of the next recipient to which the attached message should be forwarded.
class QueueItem {
  QueueItem({
    required this.message,
    required this.senderDidManager,
    required this.mediatorDid,
    required this.next,
  }) {
    id = const Uuid().v4();
  }
  final PlainTextMessage message;
  final DidManager senderDidManager;
  final String mediatorDid;
  final String next;

  late final String id;
}

class SendMessageQueue {
  SendMessageQueue({MeetingPlaceMediatorSDKLogger? logger})
      : _logger = logger ??
            DefaultMeetingPlaceMediatorSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'SendMessageQueue';

  final Queue<QueueItem> _queue = Queue<QueueItem>();
  final Mutex _messageDeleteMutex = Mutex();
  final MeetingPlaceMediatorSDKLogger _logger;

  Timer? _scheduledTimer;

  void add(QueueItem queueItem) {
    final methodName = 'add';
    _logger.info('Adding message to send queue', name: methodName);
    _queue.add(queueItem);
  }

  void scheduleAction(
    Future<dynamic> Function(QueueItem) action,
    int afterSeconds,
  ) {
    final methodName = 'scheduleAction';
    _logger.info(
      'Started scheduling send message action in $afterSeconds seconds',
      name: methodName,
    );
    _clearSchedule();

    _scheduledTimer = Timer(Duration(seconds: afterSeconds), () async {
      if (_queue.isEmpty) {
        _logger.warning(
          'No messages in queue to send, skipping action',
          name: methodName,
        );
        return;
      }

      try {
        await _messageDeleteMutex.acquire();

        // Log message here...
        final queueItems = _queue.toList();

        _logger.info(
          'Sending ${queueItems.length} messages from queue',
          name: methodName,
        );
        for (final queueItem in queueItems) {
          /**
           * TODO: handle errors from mediator? Currently we delete
           * all expected messages from queue but sometimes it fails only for
           * some messages
           */
          await action(queueItem);
          _queue.removeWhere((itemInQueue) => itemInQueue.id == queueItem.id);
        }
      } catch (e, stackTrace) {
        _logger.error(
          'Send message queue exception: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
          name: methodName,
        );
        Error.throwWithStackTrace(
          MediatorException.sendMessageError(innerException: e),
          stackTrace,
        );
      } finally {
        _logger.info('Completed sending messages from queue', name: methodName);
        _messageDeleteMutex.release();
      }
    });
    _logger.info(
      'Completed scheduling send message action in $afterSeconds seconds',
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
