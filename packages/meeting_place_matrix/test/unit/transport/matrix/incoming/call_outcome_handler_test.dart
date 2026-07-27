import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/src/call/mpx_call_event_type.dart';
import 'package:meeting_place_matrix/src/entity/call_outcome_record.dart';
import 'package:meeting_place_matrix/src/transport/matrix/incoming/call_outcome_handler.dart';
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

MatrixRoomEvent _outcomeEvent({
  String id = r'$outcome-event',
  String? senderDid = _senderDid,
  String? userId,
  Object? outcome,
  required DateTime timestamp,
}) => MatrixRoomEvent(
  id: id,
  type: MpxCallEventType.callOutcome,
  senderDid: senderDid,
  userId: userId ?? (senderDid == null ? '@unknown:server' : null),
  roomId: '!room:server',
  content: {if (outcome != null) MatrixEventField.callOutcome: outcome},
  timestamp: timestamp,
);

Map<String, dynamic> _record({
  String callId = _callId,
  CallOutcome outcome = CallOutcome.ended,
  bool answered = true,
  DateTime? startedAt,
}) => CallOutcomeRecord(
  callId: callId,
  outcome: outcome,
  answered: answered,
  startedAt: startedAt,
).toMap();

void main() {
  late ChatStream stream;
  late CallOutcomeHandler handler;
  late List<StreamData> emitted;

  setUp(() {
    stream = ChatStream();
    emitted = [];
    stream.listen(emitted.add);
    handler = CallOutcomeHandler(chatStream: stream, logger: _SilentLogger());
  });

  group('CallOutcomeHandler', () {
    test(
      'emits a CallOutcomeChatEvent using the server timestamp as endedAt',
      () async {
        final startedAt = DateTime.utc(2026, 1, 1, 12);
        final serverTs = DateTime.utc(2026, 1, 1, 12, 5);

        await handler.handle(
          _outcomeEvent(
            outcome: _record(startedAt: startedAt),
            timestamp: serverTs,
          ),
        );

        expect(emitted, hasLength(1));
        final event = emitted.single.event as CallOutcomeChatEvent;
        expect(event.callId, _callId);
        expect(event.outcome, CallOutcome.ended.name);
        expect(event.startedAt!.isAtSameMomentAs(startedAt), isTrue);
        expect(event.endedAt, serverTs);
      },
    );

    test(
      'ignores the payload endedAt in favour of the server timestamp',
      () async {
        final serverTs = DateTime.utc(2026, 1, 1, 12, 5);
        final payload = CallOutcomeRecord(
          callId: _callId,
          outcome: CallOutcome.ended,
          answered: true,
          endedAt: DateTime.utc(2030),
        ).toMap();

        await handler.handle(
          _outcomeEvent(outcome: payload, timestamp: serverTs),
        );

        final event = emitted.single.event as CallOutcomeChatEvent;
        expect(event.endedAt, serverTs);
      },
    );

    test('applies last-write-wins by server timestamp', () async {
      final first = DateTime.utc(2026, 1, 1, 12, 5);
      final later = DateTime.utc(2026, 1, 1, 12, 9);

      await handler.handle(_outcomeEvent(outcome: _record(), timestamp: later));
      await handler.handle(_outcomeEvent(outcome: _record(), timestamp: first));

      expect(emitted, hasLength(1));
      expect((emitted.single.event as CallOutcomeChatEvent).endedAt, later);
    });

    test('forwards a strictly later outcome for the same call', () async {
      final first = DateTime.utc(2026, 1, 1, 12, 5);
      final later = DateTime.utc(2026, 1, 1, 12, 9);

      await handler.handle(_outcomeEvent(outcome: _record(), timestamp: first));
      await handler.handle(_outcomeEvent(outcome: _record(), timestamp: later));

      expect(emitted, hasLength(2));
      expect((emitted.last.event as CallOutcomeChatEvent).endedAt, later);
    });

    test('skips an event with a null sender', () async {
      await handler.handle(
        _outcomeEvent(
          senderDid: null,
          outcome: _record(),
          timestamp: DateTime.utc(2026),
        ),
      );
      expect(emitted, isEmpty);
    });

    test('skips an event with no outcome record', () async {
      await handler.handle(_outcomeEvent(timestamp: DateTime.utc(2026)));
      expect(emitted, isEmpty);
    });

    test('skips an unparseable outcome record', () async {
      await handler.handle(
        _outcomeEvent(
          outcome: {'outcome': 'ended'},
          timestamp: DateTime.utc(2026),
        ),
      );
      expect(emitted, isEmpty);
    });
  });
}
