import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/services/matrix_call_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mocks/mocks.dart';

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

const _roomId = '!room:matrix.example.com';

/// Injects controlled memberships without a fully populated room state, mirror
/// of the harness used by [MatrixCallService] tests.
class _ServiceWithMemberships extends MatrixCallService {
  _ServiceWithMemberships({
    required super.ensureSession,
    required super.logger,
    required Map<String, List<matrix.CallMembership>> memberships,
  }) : _memberships = memberships;

  final Map<String, List<matrix.CallMembership>> _memberships;

  @override
  Map<String, List<matrix.CallMembership>> callMembershipsFromRoom(
    matrix.Room room,
    matrix.VoIP voip,
  ) => _memberships;
}

void main() {
  late MockMatrixClient client;
  late MockDidManager didManager;
  late MockMatrixRoom room;

  setUp(() {
    client = MockMatrixClient();
    didManager = MockDidManager();
    room = MockMatrixRoom();
    when(() => client.getRoomById(_roomId)).thenReturn(room);
  });

  _ServiceWithMemberships makeService(
    Map<String, List<matrix.CallMembership>> memberships,
  ) {
    final voip = MockVoIP();
    when(() => voip.client).thenReturn(client);
    return _ServiceWithMemberships(
      ensureSession:
          (DidManager _, {bool keepSyncActiveAfterLogin = false}) async =>
              client,
      logger: _NoOpLogger(),
      memberships: memberships,
    )..initializeVoIP(voip);
  }

  group('watchActiveCallMemberships', () {
    test('emits empty list when VoIP is not initialised', () async {
      final service = MatrixCallService(
        ensureSession:
            (DidManager _, {bool keepSyncActiveAfterLogin = false}) async =>
                client,
        logger: _NoOpLogger(),
      );

      final first = await service
          .watchActiveCallMemberships(didManager: didManager, roomId: _roomId)
          .first;

      expect(first, isEmpty);
    });

    test('initial snapshot returns all non-expired memberships', () async {
      final service = makeService({
        'call-1': [
          MockCallMembership(
            callId: 'call-1',
            userId: '@peer-a:matrix.example.com',
            deviceId: 'DEV_A',
          ),
          MockCallMembership(
            callId: 'call-1',
            userId: '@peer-b:matrix.example.com',
            deviceId: 'DEV_B',
          ),
        ],
      });

      final first = await service
          .watchActiveCallMemberships(didManager: didManager, roomId: _roomId)
          .first;

      expect(first.map((m) => m.userId), [
        '@peer-a:matrix.example.com',
        '@peer-b:matrix.example.com',
      ]);
    });

    test('initial snapshot filters expired memberships', () async {
      final service = makeService({
        'call-1': [
          MockCallMembership(
            callId: 'call-1',
            userId: '@live:matrix.example.com',
            deviceId: 'DEV_LIVE',
          ),
          MockCallMembership(
            callId: 'call-1',
            userId: '@stale:matrix.example.com',
            deviceId: 'DEV_STALE',
            isExpired: true,
          ),
        ],
      });

      final first = await service
          .watchActiveCallMemberships(didManager: didManager, roomId: _roomId)
          .first;

      expect(first.map((m) => m.userId), ['@live:matrix.example.com']);
    });

    test('emits empty list when the room is not synced yet', () async {
      when(() => client.getRoomById(_roomId)).thenReturn(null);
      final service = makeService(const {});

      final first = await service
          .watchActiveCallMemberships(didManager: didManager, roomId: _roomId)
          .first;

      expect(first, isEmpty);
    });
  });
}
