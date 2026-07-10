import 'dart:async';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_matrix/src/logger/default_meeting_place_matrix_sdk_logger.dart';
import 'package:meeting_place_matrix/src/matrix_session_manager.dart';
import 'package:meeting_place_matrix/src/services/matrix_room_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class MockMatrixClient extends Mock implements matrix.Client {}

class MockMatrixRoom extends Mock implements matrix.Room {}

class MockMatrixSessionManager extends Mock implements MatrixSessionManager {}

class MockDidManager extends Mock implements DidManager {}

class MockDeviceKeysList extends Mock implements matrix.DeviceKeysList {}

class MockDeviceKeys extends Mock implements matrix.DeviceKeys {}

class MockUser extends Mock implements matrix.User {
  MockUser(this._id);
  final String _id;
  @override
  String get id => _id;
}

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
      logger: DefaultMeetingPlaceMatrixSDKLogger(className: 'test'),
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

    test(
      'sends the event and skips device-key fetch when all keys are fresh',
      () async {
        final freshKeys = _freshDeviceKeysList();
        final room = MockMatrixRoom();
        final member = MockUser('@alice:matrix.example.com');
        when(() => room.encrypted).thenReturn(true);
        when(room.getParticipants).thenReturn([member]);
        when(() => client.getRoomById(_roomId)).thenReturn(room);
        when(
          () => client.userDeviceKeys,
        ).thenReturn({'@alice:matrix.example.com': freshKeys});
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
        verifyNever(() => client.updateUserDeviceKeys());
      },
    );

    test(
      'fetches device keys before sending when a member has stale keys',
      () async {
        final staleKeys = _outdatedDeviceKeysList();
        final room = MockMatrixRoom();
        final member = MockUser('@alice:matrix.example.com');
        when(() => room.encrypted).thenReturn(true);
        when(room.getParticipants).thenReturn([member]);
        when(() => client.getRoomById(_roomId)).thenReturn(room);
        when(
          () => client.userDeviceKeys,
        ).thenReturn({'@alice:matrix.example.com': staleKeys});
        when(() => client.updateUserDeviceKeys()).thenAnswer((_) async {});
        when(() => client.userDeviceKeysLoading).thenReturn(null);
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
        verify(() => client.updateUserDeviceKeys()).called(1);
      },
    );

    test('fetches device keys when a member has no keys loaded yet', () async {
      final room = MockMatrixRoom();
      final member = MockUser('@alice:matrix.example.com');
      when(() => room.encrypted).thenReturn(true);
      when(room.getParticipants).thenReturn([member]);
      when(() => client.getRoomById(_roomId)).thenReturn(room);
      // null entry — keys were never fetched (new connection)
      when(() => client.userDeviceKeys).thenReturn({});
      when(() => client.updateUserDeviceKeys()).thenAnswer((_) async {});
      when(() => client.userDeviceKeysLoading).thenReturn(null);
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
      verify(() => client.updateUserDeviceKeys()).called(1);
    });

    test(
      'awaits in-flight device-key update before calling room.sendEvent',
      () async {
        final staleKeys = _outdatedDeviceKeysList();
        final room = MockMatrixRoom();
        final member = MockUser('@alice:matrix.example.com');
        when(() => room.encrypted).thenReturn(true);
        when(room.getParticipants).thenReturn([member]);
        when(() => client.getRoomById(_roomId)).thenReturn(room);
        when(
          () => client.userDeviceKeys,
        ).thenReturn({'@alice:matrix.example.com': staleKeys});
        when(() => client.updateUserDeviceKeys()).thenAnswer((_) async {});

        final keysCompleter = Completer<void>();
        when(
          () => client.userDeviceKeysLoading,
        ).thenAnswer((_) => keysCompleter.future);
        when(
          () => room.sendEvent(any(), type: any(named: 'type')),
        ).thenAnswer((_) async => 'event-1');

        final sendFuture = service.sendRoomEvent(
          _roomId,
          'm.room.message',
          const {'body': 'hi'},
          didManager: didManager,
        );

        // Keys still loading — sendEvent must not have been called yet.
        await Future<void>.delayed(Duration.zero);
        verifyNever(() => room.sendEvent(any(), type: any(named: 'type')));

        keysCompleter.complete();
        expect(await sendFuture, 'event-1');
        verify(() => room.sendEvent(any(), type: any(named: 'type'))).called(1);
      },
    );
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

matrix.DeviceKeysList _freshDeviceKeysList() {
  final list = MockDeviceKeysList();
  when(() => list.outdated).thenReturn(false);
  when(() => list.deviceKeys).thenReturn({'device-1': MockDeviceKeys()});
  return list;
}

matrix.DeviceKeysList _outdatedDeviceKeysList() {
  final list = MockDeviceKeysList();
  when(() => list.outdated).thenReturn(true);
  when(() => list.deviceKeys).thenReturn({'device-1': MockDeviceKeys()});
  return list;
}
