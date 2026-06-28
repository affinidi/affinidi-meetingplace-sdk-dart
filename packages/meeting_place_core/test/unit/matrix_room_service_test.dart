import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/src/service/matrix/matrix_room_service.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_session_manager.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class MockMatrixClient extends Mock implements matrix.Client {}

class MockMatrixRoom extends Mock implements matrix.Room {}

class MockMatrixSessionManager extends Mock implements MatrixSessionManager {}

class MockDidManager extends Mock implements DidManager {}

const _roomId = '!room123:matrix.example.com';
final _homeserver = Uri.parse('https://matrix.example.com');

void main() {
  late MockMatrixClient client;
  late MockMatrixSessionManager sessionManager;
  late MockDidManager didManager;
  late MatrixRoomService service;

  setUp(() {
    client = MockMatrixClient();
    sessionManager = MockMatrixSessionManager();
    didManager = MockDidManager();

    when(() => sessionManager.serverName).thenReturn('matrix.example.com');
    when(() => sessionManager.homeserver).thenReturn(_homeserver);

    service = MatrixRoomService(
      ensureSession:
          (DidManager _, {bool keepSyncActiveAfterLogin = false}) async =>
              client,
      sessionManager: sessionManager,
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
        () => room.sendEvent(any(), type: any(named: 'type')),
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
}
