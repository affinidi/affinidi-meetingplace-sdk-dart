import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/matrix_service_exception.dart';
import 'package:meeting_place_matrix/src/services/matrix_call_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockMatrixClient extends Mock implements matrix.Client {}

class MockVoIP extends Mock implements matrix.VoIP {}

class MockDidManager extends Mock implements DidManager {}

class _NoOpLogger implements MeetingPlaceMatrixSDKLogger {
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
