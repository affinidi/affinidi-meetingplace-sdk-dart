import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/src/service/matrix/matrix_room_service.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_session_manager.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'event_handler/mocks/mocks.dart';

class MockMatrixClient extends Mock implements matrix.Client {}

class MockMatrixRoom extends Mock implements matrix.Room {}

class MockTimeline extends Mock implements matrix.Timeline {}

class MockMatrixSessionManager extends Mock implements MatrixSessionManager {}

class MockDidManager extends Mock implements DidManager {}

const _roomId = '!room123:matrix.example.com';
const _logKey = 'MatrixRoomService';
final _homeserver = Uri.parse('https://matrix.example.com');

void main() {
  late MockMatrixClient client;
  late MockMatrixSessionManager sessionManager;
  late MockDidManager didManager;
  late MockLogger mockLogger;
  late MatrixRoomService service;

  setUpAll(() {
    registerFallbackValue(matrix.Direction.f);
  });

  setUp(() {
    client = MockMatrixClient();
    sessionManager = MockMatrixSessionManager();
    didManager = MockDidManager();

    when(() => sessionManager.serverName).thenReturn('matrix.example.com');
    when(() => sessionManager.homeserver).thenReturn(_homeserver);

    mockLogger = MockLogger();
    when(
      () => mockLogger.warning(any(), name: any(named: 'name')),
    ).thenReturn(null);

    service = MatrixRoomService(
      ensureSession:
          (DidManager _, {bool keepSyncActiveAfterLogin = false}) async =>
              client,
      sessionManager: sessionManager,
      logger: mockLogger,
    );
  });

  group('sendRoomEvent', () {
    test('throws StateError when the room is not encrypted', () async {
      final room = MockMatrixRoom();
      when(() => room.encrypted).thenReturn(false);
      when(() => client.getRoomById(_roomId)).thenReturn(room);
      when(client.oneShotSync).thenAnswer((_) async {});

      await expectLater(
        service.sendRoomEvent(_roomId, 'm.room.message', const {
          'body': 'hi',
        }, didManager: didManager),
        throwsA(isA<StateError>()),
      );
    });

    test('sends the event when the room is encrypted', () async {
      final room = MockMatrixRoom();
      when(() => room.encrypted).thenReturn(true);
      when(() => client.getRoomById(_roomId)).thenReturn(room);
      when(
        () => room.sendEvent(any(), type: any<String>(named: 'type')),
      ).thenAnswer((_) async => 'event-1');

      final eventId = await service.sendRoomEvent(
        _roomId,
        'm.room.message',
        const {'body': 'hi'},
        didManager: didManager,
      );

      expect(eventId, 'event-1');
    });
  });

  group('leaveRoom', () {
    test('is a no-op when the room is unknown to the client', () async {
      when(() => client.getRoomById(_roomId)).thenReturn(null);

      await service.leaveRoom(_roomId, didManager: didManager);

      verifyNever(() => client.leaveRoom(any()));
    });
  });

  group('kickUser', () {
    test('throws StateError when the room is not found', () async {
      when(
        () => sessionManager.deriveUserId('did:test:bob', 'matrix.example.com'),
      ).thenReturn('@bob:matrix.example.com');
      when(() => client.getRoomById(_roomId)).thenReturn(null);

      await expectLater(
        service.kickUser(_roomId, did: 'did:test:bob', didManager: didManager),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('getLatestEventId', () {
    test('returns null when the room is unknown to the client', () async {
      when(() => client.getRoomById(_roomId)).thenReturn(null);

      final eventId = await service.getLatestEventId(
        _roomId,
        didManager: didManager,
      );

      expect(eventId, isNull);
    });
  });

  group('fetchRoomHistory', () {
    late MockMatrixRoom room;
    late MockTimeline timeline;

    setUp(() {
      room = MockMatrixRoom();
      timeline = MockTimeline();

      when(() => client.getRoomById(_roomId)).thenReturn(room);
      when(() => client.userID).thenReturn('@me:matrix.example.com');
      when(
        () => room.requestHistory(
          historyCount: any<int>(named: 'historyCount'),
          direction: any<matrix.Direction>(named: 'direction'),
        ),
      ).thenAnswer((_) async => 0);
      when(
        () => room.getTimeline(limit: any<int>(named: 'limit')),
      ).thenAnswer((_) async => timeline);
      when(() => timeline.events).thenReturn([]);
    });

    test('returns empty list when the room is unknown to the client', () async {
      when(() => client.getRoomById(_roomId)).thenReturn(null);

      final events = await service.fetchRoomHistory(
        _roomId,
        didManager: didManager,
      );

      expect(events, isEmpty);
    });

    test('skips getEventContext and calls requestHistory when sinceEventId is'
        ' null', () async {
      await service.fetchRoomHistory(_roomId, didManager: didManager);

      verifyNever(
        () => client.getEventContext(any(), any(), limit: any(named: 'limit')),
      );
      verify(
        () => room.requestHistory(
          historyCount: any(named: 'historyCount'),
          direction: matrix.Direction.f,
        ),
      ).called(1);
    });

    test('sets room.prev_batch from getEventContext token when sinceEventId is'
        ' provided', () async {
      const sinceEventId = r'$marker-event';
      const paginationToken = 'pagination-token-abc';

      when(
        () => client.getEventContext(_roomId, sinceEventId, limit: 0),
      ).thenAnswer((_) async => matrix.EventContext(end: paginationToken));

      await service.fetchRoomHistory(
        _roomId,
        didManager: didManager,
        sinceEventId: sinceEventId,
      );

      verify(
        () => client.getEventContext(_roomId, sinceEventId, limit: 0),
      ).called(1);
      // prev_batch is a plain field; the room absorbs the write.
      verify(() => room.prev_batch = paginationToken).called(1);
    });

    test(
      'falls back to room.prev_batch and logs a warning when getEventContext '
      'throws MatrixException (M_NOT_FOUND)',
      () async {
        const sinceEventId = r'$missing-event';

        when(
          () => client.getEventContext(_roomId, sinceEventId, limit: 0),
        ).thenThrow(
          matrix.MatrixException.fromJson({
            'errcode': 'M_NOT_FOUND',
            'error': 'Event not found.',
          }),
        );

        final events = await service.fetchRoomHistory(
          _roomId,
          didManager: didManager,
          sinceEventId: sinceEventId,
        );

        // requestHistory is still invoked; no exception propagates.
        verify(
          () => room.requestHistory(
            historyCount: any(named: 'historyCount'),
            direction: matrix.Direction.f,
          ),
        ).called(1);
        verify(() => mockLogger.warning(any(), name: _logKey)).called(1);
        expect(events, isEmpty);
      },
    );
  });
}
