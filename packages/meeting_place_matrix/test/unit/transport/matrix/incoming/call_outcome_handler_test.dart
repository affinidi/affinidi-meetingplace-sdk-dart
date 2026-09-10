import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/src/call/call_event_signer.dart';
import 'package:meeting_place_matrix/src/call/mpx_call_event_type.dart';
import 'package:meeting_place_matrix/src/entity/call_outcome_record.dart';
import 'package:meeting_place_matrix/src/transport/matrix/incoming/call_outcome_handler.dart';
import 'package:meeting_place_matrix/src/transport/matrix/incoming/trusted_call_start_time_store.dart';
import 'package:meeting_place_matrix/src/transport/matrix/matrix_media_attachment.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
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

class _MockDidResolver extends Mock implements DidResolver {}

const _callId = 'room123@1000';
const _callEventSigner = CallEventSigner();

Future<DidManager> _newDidManager() async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
  final key = await wallet.generateKey(keyType: KeyType.ed25519);
  await didManager.addVerificationMethod(key.id);
  return didManager;
}

MatrixRoomEvent _outcomeEvent({
  String id = r'$outcome-event',
  String? senderDid,
  String? userId,
  Object? outcome,
  String? signature,
  required DateTime timestamp,
}) => MatrixRoomEvent(
  id: id,
  type: MpxCallEventType.callOutcome,
  senderDid: senderDid,
  userId: userId ?? (senderDid == null ? '@unknown:server' : null),
  roomId: '!room:server',
  content: {
    MatrixEventField.callOutcome: ?outcome,
    MatrixEventField.callSignature: ?signature,
  },
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
  late _MockDidResolver didResolver;
  late DidManager senderDidManager;
  late String senderDid;

  setUp(() async {
    stream = ChatStream();
    emitted = [];
    stream.listen(emitted.add);
    didResolver = _MockDidResolver();
    handler = CallOutcomeHandler(
      chatStream: stream,
      logger: _SilentLogger(),
      didResolver: didResolver,
    );

    senderDidManager = await _newDidManager();
    final didDocument = await senderDidManager.getDidDocument();
    senderDid = didDocument.id;
    when(
      () => didResolver.resolveDid(senderDid),
    ).thenAnswer((_) async => didDocument);
  });

  Future<String> signRecord(Map<String, dynamic> record) => _callEventSigner
      .sign(callFields: record, senderDidManager: senderDidManager);

  group('CallOutcomeHandler', () {
    test(
      'emits a CallOutcomeChatEvent using the server timestamp as endedAt',
      () async {
        final startedAt = DateTime.utc(2026, 1, 1, 12);
        final serverTs = DateTime.utc(2026, 1, 1, 12, 5);
        final record = _record(startedAt: startedAt);

        await handler.handle(
          _outcomeEvent(
            outcome: record,
            timestamp: serverTs,
            senderDid: senderDid,
            signature: await signRecord(record),
          ),
        );
        await Future<void>.delayed(Duration.zero);

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
          _outcomeEvent(
            outcome: payload,
            timestamp: serverTs,
            senderDid: senderDid,
            signature: await signRecord(payload),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final event = emitted.single.event as CallOutcomeChatEvent;
        expect(event.endedAt, serverTs);
      },
    );

    test('applies last-write-wins by server timestamp', () async {
      final first = DateTime.utc(2026, 1, 1, 12, 5);
      final later = DateTime.utc(2026, 1, 1, 12, 9);
      final record = _record();
      final signature = await signRecord(record);

      await handler.handle(
        _outcomeEvent(
          outcome: record,
          timestamp: later,
          senderDid: senderDid,
          signature: signature,
        ),
      );
      await handler.handle(
        _outcomeEvent(
          outcome: record,
          timestamp: first,
          senderDid: senderDid,
          signature: signature,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(1));
      expect((emitted.single.event as CallOutcomeChatEvent).endedAt, later);
    });

    test('forwards a strictly later outcome for the same call', () async {
      final first = DateTime.utc(2026, 1, 1, 12, 5);
      final later = DateTime.utc(2026, 1, 1, 12, 9);
      final record = _record();
      final signature = await signRecord(record);

      await handler.handle(
        _outcomeEvent(
          outcome: record,
          timestamp: first,
          senderDid: senderDid,
          signature: signature,
        ),
      );
      await handler.handle(
        _outcomeEvent(
          outcome: record,
          timestamp: later,
          senderDid: senderDid,
          signature: signature,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(2));
      expect((emitted.last.event as CallOutcomeChatEvent).endedAt, later);
    });

    test('skips an event with a null sender', () async {
      final record = _record();
      await handler.handle(
        _outcomeEvent(
          senderDid: null,
          outcome: record,
          timestamp: DateTime.utc(2026),
          signature: await signRecord(record),
        ),
      );
      expect(emitted, isEmpty);
    });

    test('skips an event with no outcome record', () async {
      await handler.handle(
        _outcomeEvent(timestamp: DateTime.utc(2026), senderDid: senderDid),
      );
      expect(emitted, isEmpty);
    });

    test('skips an unparseable outcome record', () async {
      await handler.handle(
        _outcomeEvent(
          outcome: {'outcome': 'ended'},
          timestamp: DateTime.utc(2026),
          senderDid: senderDid,
        ),
      );
      expect(emitted, isEmpty);
    });

    test('skips an unsigned event', () async {
      await handler.handle(
        _outcomeEvent(
          outcome: _record(),
          timestamp: DateTime.utc(2026),
          senderDid: senderDid,
        ),
      );
      expect(emitted, isEmpty);
    });

    test(
      'skips an event signed by a DID other than the claimed sender '
      '(a non-participant forging a delayed outcome to manipulate duration)',
      () async {
        final otherDidManager = await _newDidManager();
        final record = _record();
        final otherSignature = await _callEventSigner.sign(
          callFields: record,
          senderDidManager: otherDidManager,
        );

        await handler.handle(
          _outcomeEvent(
            outcome: record,
            timestamp: DateTime.utc(2026, 1, 1, 12, 30),
            senderDid: senderDid,
            signature: otherSignature,
          ),
        );

        expect(emitted, isEmpty);
      },
    );

    test(
      'skips an event whose signature does not match its outcome record',
      () async {
        final signedRecord = _record();
        final sentRecord = _record(outcome: CallOutcome.cancelled);

        await handler.handle(
          _outcomeEvent(
            outcome: sentRecord,
            timestamp: DateTime.utc(2026),
            senderDid: senderDid,
            signature: await signRecord(signedRecord),
          ),
        );

        expect(emitted, isEmpty);
      },
    );
  });

  group('CallOutcomeHandler with a TrustedCallStartTimeStore', () {
    late TrustedCallStartTimeStore startTimeStore;

    setUp(() {
      startTimeStore = TrustedCallStartTimeStore();
      handler = CallOutcomeHandler(
        chatStream: stream,
        logger: _SilentLogger(),
        didResolver: didResolver,
        startTimeStore: startTimeStore,
      );
    });

    test(
      'prefers the trustworthy stored start time over the payload value',
      () async {
        final trustedStartedAt = DateTime.utc(2026, 1, 1, 12);
        final forgedStartedAt = DateTime.utc(2000);
        startTimeStore.recordIfAbsent(_callId, trustedStartedAt);
        final record = _record(startedAt: forgedStartedAt);

        await handler.handle(
          _outcomeEvent(
            outcome: record,
            timestamp: DateTime.utc(2026, 1, 1, 12, 5),
            senderDid: senderDid,
            signature: await signRecord(record),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final event = emitted.single.event as CallOutcomeChatEvent;
        expect(event.startedAt!.isAtSameMomentAs(trustedStartedAt), isTrue);
      },
    );

    test(
      'falls back to the payload startedAt when no started event was seen',
      () async {
        final payloadStartedAt = DateTime.utc(2026, 1, 1, 12);
        final record = _record(startedAt: payloadStartedAt);

        await handler.handle(
          _outcomeEvent(
            outcome: record,
            timestamp: DateTime.utc(2026, 1, 1, 12, 5),
            senderDid: senderDid,
            signature: await signRecord(record),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final event = emitted.single.event as CallOutcomeChatEvent;
        expect(event.startedAt!.isAtSameMomentAs(payloadStartedAt), isTrue);
      },
    );
  });
}
