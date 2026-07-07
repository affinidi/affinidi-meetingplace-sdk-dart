import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/matrix_service_exception.dart';
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

const _roomId = '!room123:matrix.example.com';
const _callId = 'call-1';
const _ownUserId = '@own:matrix.example.com';
const _ownDeviceId = 'OWNDEVICE';
const _peerCallId = 'call-peer-1';

/// Subclass that injects memberships directly into `callMembershipsFromRoom`
/// without requiring a fully populated Matrix room state structure. Necessary
/// because `getCallMembershipsFromRoom` is an extension method and cannot be
/// overridden via the `matrix.Room` interface in tests.
class _MatrixCallServiceWithMemberships extends MatrixCallService {
  _MatrixCallServiceWithMemberships({
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

class _MatrixCallServiceCapturingVoip extends MatrixCallService {
  _MatrixCallServiceCapturingVoip({
    required super.ensureSession,
    required super.logger,
  });

  matrix.VoIP? lastVoip;

  @override
  Map<String, List<matrix.CallMembership>> callMembershipsFromRoom(
    matrix.Room room,
    matrix.VoIP voip,
  ) {
    lastVoip = voip;
    return const {};
  }
}

class _MatrixCallServiceCapturingMemberships extends MatrixCallService {
  _MatrixCallServiceCapturingMemberships({
    required super.ensureSession,
    required super.logger,
  });

  matrix.VoIP? lastVoip;
  Map<String, List<matrix.CallMembership>> memberships = const {};

  @override
  Map<String, List<matrix.CallMembership>> callMembershipsFromRoom(
    matrix.Room room,
    matrix.VoIP voip,
  ) {
    lastVoip = voip;
    return memberships;
  }
}

class _MatrixCallServiceWithVoipFactory extends MatrixCallService {
  _MatrixCallServiceWithVoipFactory({
    required super.ensureSession,
    required super.logger,
    required this.voipFactory,
  });

  final matrix.VoIP Function(
    matrix.Client client,
    matrix.WebRTCDelegate delegate,
  ) voipFactory;

  @override
  matrix.VoIP createVoip(
    matrix.Client client,
    matrix.WebRTCDelegate delegate,
  ) => voipFactory(client, delegate);
}

void main() {
  late MockMatrixClient client;
  late MockMatrixClient secondClient;
  late MockDidManager didManager;
  late MockDidManager secondDidManager;
  late MatrixCallService service;

  setUp(() {
    client = MockMatrixClient();
    secondClient = MockMatrixClient();
    didManager = MockDidManager();
    secondDidManager = MockDidManager();
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
      final voip = MockVoIP();
      when(() => voip.client).thenReturn(client);
      service.initializeVoIP(voip);
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

  group('initializeVoIPWithDelegate', () {
    test('reuses an existing VoIP instance instead of overwriting it', () async {
      final mockRoom = MockMatrixRoom();
      final existingVoip = MockVoIP();
      final delegate = MockWebRTCDelegate();
      final capturingService = _MatrixCallServiceCapturingVoip(
        ensureSession:
            (DidManager _, {bool keepSyncActiveAfterLogin = false}) async =>
                client,
        logger: _NoOpLogger(),
      );

      when(() => existingVoip.client).thenReturn(client);
      when(() => existingVoip.delegate).thenReturn(delegate);
      capturingService.initializeVoIP(existingVoip);
      when(() => client.getRoomById(_roomId)).thenReturn(mockRoom);
      when(() => client.userID).thenReturn(_ownUserId);
      when(() => client.deviceID).thenReturn(_ownDeviceId);

      await capturingService.initializeVoIPWithDelegate(
        didManager: didManager,
        delegate: delegate,
      );

      await capturingService.activeCallId(
        didManager: didManager,
        roomId: _roomId,
      );

      expect(capturingService.lastVoip, same(existingVoip));
    });

    test('throws when a different delegate is used for an existing VoIP', () async {
      final existingVoip = MockVoIP();
      final originalDelegate = MockWebRTCDelegate();
      final replacementDelegate = MockWebRTCDelegate();

      when(() => existingVoip.client).thenReturn(client);
      when(() => existingVoip.delegate).thenReturn(originalDelegate);
      service.initializeVoIP(existingVoip);

      await expectLater(
        service.initializeVoIPWithDelegate(
          didManager: didManager,
          delegate: replacementDelegate,
        ),
        throwsA(isA<MatrixServiceException>()),
      );
    });

    test('allows a different client to have its own VoIP instance', () async {
      final firstDelegate = MockWebRTCDelegate();
      final secondDelegate = MockWebRTCDelegate();
      final firstVoip = MockVoIP();
      final secondVoip = MockVoIP();
      final multiClientService = _MatrixCallServiceWithVoipFactory(
        ensureSession:
            (DidManager input, {bool keepSyncActiveAfterLogin = false}) async =>
                identical(input, didManager) ? client : secondClient,
        logger: _NoOpLogger(),
        voipFactory: (factoryClient, factoryDelegate) {
          if (identical(factoryClient, client) &&
              identical(factoryDelegate, firstDelegate)) {
            return firstVoip;
          }
          if (identical(factoryClient, secondClient) &&
              identical(factoryDelegate, secondDelegate)) {
            return secondVoip;
          }
          throw StateError('Unexpected VoIP factory arguments');
        },
      );

      when(() => firstVoip.client).thenReturn(client);
      when(() => firstVoip.delegate).thenReturn(firstDelegate);
      when(() => secondVoip.client).thenReturn(secondClient);
      when(() => secondVoip.delegate).thenReturn(secondDelegate);

      await multiClientService.initializeVoIPWithDelegate(
        didManager: didManager,
        delegate: firstDelegate,
      );

      await expectLater(
        multiClientService.initializeVoIPWithDelegate(
          didManager: secondDidManager,
          delegate: secondDelegate,
        ),
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
      final voip = MockVoIP();
      when(() => voip.client).thenReturn(client);
      service.initializeVoIP(voip);
      when(() => client.getRoomById(_roomId)).thenReturn(null);

      final result = await service.activeCallId(
        didManager: didManager,
        roomId: _roomId,
      );
      expect(result, isNull);
    });

    test('uses the VoIP bound to the requested client', () async {
      final firstVoip = MockVoIP();
      final secondVoip = MockVoIP();
      final firstRoom = MockMatrixRoom();
      final secondRoom = MockMatrixRoom();
      final capturingService = _MatrixCallServiceCapturingMemberships(
        ensureSession:
            (DidManager input, {bool keepSyncActiveAfterLogin = false}) async =>
                identical(input, didManager) ? client : secondClient,
        logger: _NoOpLogger(),
      );

      when(() => firstVoip.client).thenReturn(client);
      when(() => secondVoip.client).thenReturn(secondClient);
      capturingService.initializeVoIP(firstVoip);
      capturingService.initializeVoIP(secondVoip);
      when(() => client.getRoomById(_roomId)).thenReturn(firstRoom);
      when(() => secondClient.getRoomById(_roomId)).thenReturn(secondRoom);
      when(() => secondClient.userID).thenReturn(_ownUserId);
      when(() => secondClient.deviceID).thenReturn(_ownDeviceId);

      await capturingService.activeCallId(
        didManager: secondDidManager,
        roomId: _roomId,
      );

      expect(capturingService.lastVoip, same(secondVoip));
    });

    group('skip-own-membership', () {
      late MockMatrixClient skipClient;
      late MockDidManager skipDidManager;
      late MockMatrixRoom mockRoom;

      setUp(() {
        skipClient = MockMatrixClient();
        skipDidManager = MockDidManager();
        mockRoom = MockMatrixRoom();
        when(() => skipClient.userID).thenReturn(_ownUserId);
        when(() => skipClient.deviceID).thenReturn(_ownDeviceId);
        when(() => skipClient.getRoomById(_roomId)).thenReturn(mockRoom);
      });

      _MatrixCallServiceWithMemberships makeService(
        Map<String, List<matrix.CallMembership>> memberships,
      ) {
        final voip = MockVoIP();
        when(() => voip.client).thenReturn(skipClient);
        return _MatrixCallServiceWithMemberships(
          ensureSession:
              (DidManager _, {bool keepSyncActiveAfterLogin = false}) async =>
                  skipClient,
          logger: _NoOpLogger(),
          memberships: memberships,
        )..initializeVoIP(voip);
      }

      test('returns peer callId when own membership is present', () async {
        final svc = makeService({
          'call-own-1': [
            MockCallMembership(
              callId: 'call-own-1',
              userId: _ownUserId,
              deviceId: _ownDeviceId,
            ),
          ],
          _peerCallId: [
            MockCallMembership(
              callId: _peerCallId,
              userId: '@peer:matrix.example.com',
              deviceId: 'PEERDEVICE',
            ),
          ],
        });

        final result = await svc.activeCallId(
          didManager: skipDidManager,
          roomId: _roomId,
        );

        expect(result, equals(_peerCallId));
      });

      test('returns null when only own membership is present', () async {
        final svc = makeService({
          'call-own-1': [
            MockCallMembership(
              callId: 'call-own-1',
              userId: _ownUserId,
              deviceId: _ownDeviceId,
            ),
          ],
        });

        final result = await svc.activeCallId(
          didManager: skipDidManager,
          roomId: _roomId,
        );

        expect(result, isNull);
      });

      test('skips expired peer membership before own-device check', () async {
        final svc = makeService({
          _peerCallId: [
            MockCallMembership(
              callId: _peerCallId,
              userId: '@peer:matrix.example.com',
              deviceId: 'PEERDEVICE',
              isExpired: true,
            ),
          ],
        });

        final result = await svc.activeCallId(
          didManager: skipDidManager,
          roomId: _roomId,
        );

        expect(result, isNull);
      });
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
