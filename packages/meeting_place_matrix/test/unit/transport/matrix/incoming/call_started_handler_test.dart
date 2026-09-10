import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/src/call/call_event_signer.dart';
import 'package:meeting_place_matrix/src/call/mpx_call_event_type.dart';
import 'package:meeting_place_matrix/src/transport/matrix/incoming/call_started_handler.dart';
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

MatrixRoomEvent _startedEvent({
  String id = r'$started-event',
  String? senderDid,
  String? userId,
  Object? callId,
  String? signature,
  required DateTime timestamp,
}) => MatrixRoomEvent(
  id: id,
  type: MpxCallEventType.callStarted,
  senderDid: senderDid,
  userId: userId ?? (senderDid == null ? '@unknown:server' : null),
  roomId: '!room:server',
  content: {
    MatrixEventField.callId: ?callId,
    MatrixEventField.callSignature: ?signature,
  },
  timestamp: timestamp,
);

void main() {
  late TrustedCallStartTimeStore startTimeStore;
  late CallStartedHandler handler;
  late _MockDidResolver didResolver;
  late DidManager senderDidManager;
  late String senderDid;

  setUp(() async {
    startTimeStore = TrustedCallStartTimeStore();
    didResolver = _MockDidResolver();
    handler = CallStartedHandler(
      startTimeStore: startTimeStore,
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

  Future<String> signCallId(String callId) => _callEventSigner.sign(
    callFields: {MatrixEventField.callId: callId},
    senderDidManager: senderDidManager,
  );

  group('CallStartedHandler', () {
    test(
      'records the server timestamp as the trustworthy start time',
      () async {
        final serverTs = DateTime.utc(2026, 1, 1, 12);
        final signature = await signCallId(_callId);

        await handler.handle(
          _startedEvent(
            callId: _callId,
            timestamp: serverTs,
            senderDid: senderDid,
            signature: signature,
          ),
        );

        expect(startTimeStore[_callId], serverTs);
      },
    );

    test(
      'keeps the earliest timestamp when a later duplicate arrives',
      () async {
        final first = DateTime.utc(2026, 1, 1, 12);
        final later = DateTime.utc(2026, 1, 1, 12, 5);
        final signature = await signCallId(_callId);

        await handler.handle(
          _startedEvent(
            callId: _callId,
            timestamp: first,
            senderDid: senderDid,
            signature: signature,
          ),
        );
        await handler.handle(
          _startedEvent(
            callId: _callId,
            timestamp: later,
            senderDid: senderDid,
            signature: signature,
          ),
        );

        expect(startTimeStore[_callId], first);
      },
    );

    test('keeps the earliest timestamp when an earlier duplicate arrives '
        'out of order', () async {
      final first = DateTime.utc(2026, 1, 1, 12);
      final earlier = DateTime.utc(2026, 1, 1, 11);
      final signature = await signCallId(_callId);

      await handler.handle(
        _startedEvent(
          callId: _callId,
          timestamp: first,
          senderDid: senderDid,
          signature: signature,
        ),
      );
      await handler.handle(
        _startedEvent(
          callId: _callId,
          timestamp: earlier,
          senderDid: senderDid,
          signature: signature,
        ),
      );

      expect(startTimeStore[_callId], earlier);
    });

    test('skips an event with no callId', () async {
      await handler.handle(
        _startedEvent(
          timestamp: DateTime.utc(2026),
          senderDid: senderDid,
          signature: await signCallId(''),
        ),
      );
      expect(startTimeStore[_callId], isNull);
    });

    test('skips an event with an empty callId', () async {
      await handler.handle(
        _startedEvent(
          callId: '',
          timestamp: DateTime.utc(2026),
          senderDid: senderDid,
          signature: await signCallId(''),
        ),
      );
      expect(startTimeStore[_callId], isNull);
    });

    test('skips an event with no sender DID', () async {
      await handler.handle(
        _startedEvent(
          callId: _callId,
          timestamp: DateTime.utc(2026),
          signature: await signCallId(_callId),
        ),
      );
      expect(startTimeStore[_callId], isNull);
    });

    test('skips an unsigned event', () async {
      await handler.handle(
        _startedEvent(
          callId: _callId,
          timestamp: DateTime.utc(2026),
          senderDid: senderDid,
        ),
      );
      expect(startTimeStore[_callId], isNull);
    });

    test(
      'skips an event signed by a DID other than the claimed sender',
      () async {
        final otherDidManager = await _newDidManager();
        final otherSignature = await _callEventSigner.sign(
          callFields: {MatrixEventField.callId: _callId},
          senderDidManager: otherDidManager,
        );

        await handler.handle(
          _startedEvent(
            callId: _callId,
            timestamp: DateTime.utc(2026),
            senderDid: senderDid,
            signature: otherSignature,
          ),
        );

        expect(startTimeStore[_callId], isNull);
      },
    );

    test('skips an event whose signature does not match its callId', () async {
      final signatureForOtherCallId = await signCallId('a-different-call');

      await handler.handle(
        _startedEvent(
          callId: _callId,
          timestamp: DateTime.utc(2026),
          senderDid: senderDid,
          signature: signatureForOtherCallId,
        ),
      );

      expect(startTimeStore[_callId], isNull);
    });
  });
}
