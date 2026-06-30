import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_call_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockMatrixClient extends Mock implements matrix.Client {}

class MockVoIP extends Mock implements matrix.VoIP {}

class MockDidManager extends Mock implements DidManager {}

class MockMatrixRoom extends Mock implements matrix.Room {}

class _NoOpLogger implements MeetingPlaceCoreSDKLogger {
  @override
  void info(String message, {String name = ''}) {}

  @override
  void warning(String message, {String name = ''}) {}

  @override
  void debug(String message, {String name = ''}) {}

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = '',
  }) {}
}

const _roomId = '!room123:matrix.example.com';
const _callId = 'call-1';
const _ownUserId = '@own:matrix.example.com';
const _ownDeviceId = 'OWNDEVICE';
const _peerUserId = '@peer:matrix.example.com';
const _peerDeviceId = 'PEERDEVICE';
const _peerCallId = 'peer-call-1';

matrix.Event _memberEvent({
  required matrix.Room room,
  required matrix.VoIP voip,
  required String userId,
  required String deviceId,
  required String callId,
}) {
  return matrix.Event(
    content: {
      'memberships': [
        matrix.CallMembership(
          userId: userId,
          callId: callId,
          backend: matrix.LiveKitBackend(
            livekitServiceUrl: 'wss://livekit.example.com',
            livekitAlias: 'alias',
          ),
          deviceId: deviceId,
          expiresTs: DateTime.now()
              .add(const Duration(hours: 12))
              .millisecondsSinceEpoch,
          roomId: _roomId,
          membershipId: 'session-$deviceId',
          voip: voip,
        ).toJson(),
      ],
    },
    type: matrix.EventTypes.GroupCallMember,
    eventId: 'evt-$userId',
    senderId: userId,
    originServerTs: DateTime.now(),
    room: room,
    stateKey: userId,
  );
}

void main() {
  late MockMatrixClient client;
  late MockDidManager didManager;
  late MatrixCallService service;

  setUp(() {
    client = MockMatrixClient();
    didManager = MockDidManager();
    service = MatrixCallService(
      ensureSession:
          (DidManager _, {bool keepSyncActiveAfterLogin = false}) async =>
              client,
      logger: _NoOpLogger(),
    );
  });

  group('startCall', () {
    test('throws when VoIP is not initialized', () async {
      await expectLater(
        service.startCall(
          didManager: didManager,
          roomId: _roomId,
          livekitServiceUrl: 'wss://livekit.example.com',
          livekitAlias: 'alias',
        ),
        throwsA(isA<MatrixServiceException>()),
      );
    });

    test('throws when the room is not found', () async {
      service.initializeVoIP(MockVoIP());
      when(() => client.getRoomById(_roomId)).thenReturn(null);

      await expectLater(
        service.startCall(
          didManager: didManager,
          roomId: _roomId,
          livekitServiceUrl: 'wss://livekit.example.com',
          livekitAlias: 'alias',
        ),
        throwsA(isA<MatrixServiceException>()),
      );
    });
  });

  group('leaveCall', () {
    test('returns normally when VoIP is not initialized', () async {
      await expectLater(
        service.leaveCall(roomId: _roomId, callId: _callId),
        completes,
      );
    });
  });

  group('activeCallId', () {
    test('returns null when VoIP is not initialized', () async {
      final result = await service.activeCallId(
        didManager: didManager,
        roomId: _roomId,
      );
      expect(result, isNull);
    });

    test('returns null when the room is not found', () async {
      service.initializeVoIP(MockVoIP());
      when(() => client.getRoomById(_roomId)).thenReturn(null);

      final result = await service.activeCallId(
        didManager: didManager,
        roomId: _roomId,
      );
      expect(result, isNull);
    });

    test('ignores this device\'s own stale membership', () async {
      final voip = MockVoIP();
      final room = MockMatrixRoom();
      when(() => voip.timeouts).thenReturn(matrix.CallTimeouts());
      service.initializeVoIP(voip);

      when(() => client.userID).thenReturn(_ownUserId);
      when(() => client.deviceID).thenReturn(_ownDeviceId);
      when(() => client.getRoomById(_roomId)).thenReturn(room);
      when(() => room.id).thenReturn(_roomId);
      when(() => room.states).thenReturn({
        matrix.EventTypes.GroupCallMember: {
          _ownUserId: _memberEvent(
            room: room,
            voip: voip,
            userId: _ownUserId,
            deviceId: _ownDeviceId,
            callId: _callId,
          ),
        },
      });

      final result = await service.activeCallId(
        didManager: didManager,
        roomId: _roomId,
      );
      expect(result, isNull);
    });

    test('returns the peer call id when the peer is in the call', () async {
      final voip = MockVoIP();
      final room = MockMatrixRoom();
      when(() => voip.timeouts).thenReturn(matrix.CallTimeouts());
      service.initializeVoIP(voip);

      when(() => client.userID).thenReturn(_ownUserId);
      when(() => client.deviceID).thenReturn(_ownDeviceId);
      when(() => client.getRoomById(_roomId)).thenReturn(room);
      when(() => room.id).thenReturn(_roomId);
      when(() => room.states).thenReturn({
        matrix.EventTypes.GroupCallMember: {
          _ownUserId: _memberEvent(
            room: room,
            voip: voip,
            userId: _ownUserId,
            deviceId: _ownDeviceId,
            callId: _callId,
          ),
          _peerUserId: _memberEvent(
            room: room,
            voip: voip,
            userId: _peerUserId,
            deviceId: _peerDeviceId,
            callId: _peerCallId,
          ),
        },
      });

      final result = await service.activeCallId(
        didManager: didManager,
        roomId: _roomId,
      );
      expect(result, _peerCallId);
    });
  });

  group('watchCall', () {
    test('returns null when VoIP is not initialized', () {
      expect(service.watchCall(roomId: _roomId, callId: _callId), isNull);
    });
  });

  group('dispose', () {
    test('is safe to call multiple times', () async {
      await service.dispose();
      await expectLater(service.dispose(), completes);
    });
  });
}
