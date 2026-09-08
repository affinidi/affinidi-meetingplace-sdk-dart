import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/src/call/mpx_call_event_type.dart';
import 'package:meeting_place_matrix/src/transport/matrix/incoming/call_started_handler.dart';
import 'package:meeting_place_matrix/src/transport/matrix/incoming/trusted_call_start_time_store.dart';
import 'package:meeting_place_matrix/src/transport/matrix/matrix_media_attachment.dart';
import 'package:test/test.dart';

import '../../../../meeting_place_matrix.dart';

class _SilentLogger implements MeetingPlaceChatSDKLogger {
  @override
  void debug(String message, {String name = ''}) {}
  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = '',
  }) {}
  @override
  void info(String message, {String name = ''}) {}
  @override
  void warning(String message, {String name = ''}) {}
}

const _senderDid = 'did:test:alice';
const _callId = 'room123@1000';

MatrixRoomEvent _startedEvent({
  String id = r'$started-event',
  String? senderDid = _senderDid,
  String? userId,
  Object? callId,
  required DateTime timestamp,
}) => MatrixRoomEvent(
  id: id,
  type: MpxCallEventType.callStarted,
  senderDid: senderDid,
  userId: userId ?? (senderDid == null ? '@unknown:server' : null),
  roomId: '!room:server',
  content: {MatrixEventField.callId: ?callId},
  timestamp: timestamp,
);

void main() {
  late TrustedCallStartTimeStore startTimeStore;
  late CallStartedHandler handler;

  setUp(() {
    startTimeStore = TrustedCallStartTimeStore();
    handler = CallStartedHandler(
      startTimeStore: startTimeStore,
      logger: _SilentLogger(),
    );
  });

  group('CallStartedHandler', () {
    test(
      'records the server timestamp as the trustworthy start time',
      () async {
        final serverTs = DateTime.utc(2026, 1, 1, 12);

        await handler.handle(
          _startedEvent(callId: _callId, timestamp: serverTs),
        );

        expect(startTimeStore[_callId], serverTs);
      },
    );

    test(
      'keeps the earliest timestamp when a later duplicate arrives',
      () async {
        final first = DateTime.utc(2026, 1, 1, 12);
        final later = DateTime.utc(2026, 1, 1, 12, 5);

        await handler.handle(_startedEvent(callId: _callId, timestamp: first));
        await handler.handle(_startedEvent(callId: _callId, timestamp: later));

        expect(startTimeStore[_callId], first);
      },
    );

    test('ignores an out-of-order duplicate posted before the first', () async {
      final first = DateTime.utc(2026, 1, 1, 12);
      final earlier = DateTime.utc(2026, 1, 1, 11);

      await handler.handle(_startedEvent(callId: _callId, timestamp: first));
      await handler.handle(_startedEvent(callId: _callId, timestamp: earlier));

      expect(startTimeStore[_callId], first);
    });

    test('skips an event with no callId', () async {
      await handler.handle(_startedEvent(timestamp: DateTime.utc(2026)));
      expect(startTimeStore[_callId], isNull);
    });

    test('skips an event with an empty callId', () async {
      await handler.handle(
        _startedEvent(callId: '', timestamp: DateTime.utc(2026)),
      );
      expect(startTimeStore[_callId], isNull);
    });
  });
}
