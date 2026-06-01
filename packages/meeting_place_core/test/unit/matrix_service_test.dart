import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_auth_exception.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_client_cache.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_service_exception.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_session_manager.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Mocks & fakes
// ---------------------------------------------------------------------------

class MockControlPlaneSDK extends Mock implements ControlPlaneSDK {}

class MockDidManager extends Mock implements DidManager {}

class MockDidDocument extends Mock implements DidDocument {}

class MockMatrixClient extends Mock implements matrix.Client {}

class MockMatrixSessionManager extends Mock implements MatrixSessionManager {}

class FakeMatrixTokenCommand extends Fake implements MatrixTokenCommand {}

class FakeStateEvent extends Fake implements matrix.StateEvent {}

/// A [MatrixClientCache] that accepts pre-seeded [matrix.Client] entries
/// without going through `MatrixClient.init`.
class _FakeClientCache extends MatrixClientCache {
  _FakeClientCache()
    : super(homeserver: Uri.parse('https://matrix.example.com'));

  final Map<String, Future<matrix.Client>> _clients = {};

  void seed(String did, matrix.Client client) =>
      _clients[did] = Future.value(client);

  void seedFuture(String did, Future<matrix.Client> future) =>
      _clients[did] = future;

  @override
  Future<matrix.Client>? get({required String did}) => _clients[did];

  @override
  void add({required String did, required Future<matrix.Client> future}) {
    _clients[did] = future;
  }

  @override
  void remove({required String did}) => _clients.remove(did);
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

const _testDid = 'did:test:alice';
const _matrixUserId = '@hash:matrix.example.com';
const _testJwt = 'test.jwt.token';
const _testRoomId = '!room123:matrix.example.com';

final _testHomeserver = Uri.parse('https://matrix.example.com');

MatrixConfig _fakeConfig() => MatrixConfig(
  mediatorDid: 'did:test:mediator',
  controlPlaneDid: 'did:test:control-plane',
  homeserver: _testHomeserver,
  databaseFactory: const _NoOpDatabaseFactory(),
);

/// Produces a [MockMatrixClient] that reports a valid, non-expiring session.
MockMatrixClient _validClient() {
  final client = MockMatrixClient();
  when(() => client.accessToken).thenReturn('valid-token');
  when(
    () => client.accessTokenExpiresAt,
  ).thenReturn(DateTime.now().add(const Duration(hours: 1)));
  return client;
}

/// Produces a [MockMatrixClient] whose token is within the grace period.
MockMatrixClient _expiringSoonClient() {
  final client = MockMatrixClient();
  when(() => client.accessToken).thenReturn('expiring-token');
  when(
    () => client.accessTokenExpiresAt,
  ).thenReturn(DateTime.now().add(const Duration(seconds: 30)));
  return client;
}

/// Produces a [MockMatrixClient] with no access token (soft-logout).
MockMatrixClient _unauthenticatedClient() {
  final client = MockMatrixClient();
  when(() => client.accessToken).thenReturn(null);
  return client;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMatrixTokenCommand());
    registerFallbackValue(<matrix.StateEvent>[FakeStateEvent()]);
  });

  // =========================================================================
  // MatrixSessionManager
  // =========================================================================

  group('MatrixSessionManager', () {
    late _FakeClientCache cache;
    late MatrixSessionManager manager;

    setUp(() {
      cache = _FakeClientCache();
      manager = MatrixSessionManager(
        config: _fakeConfig(),
        logger: _NoOpLogger(),
        clientCache: cache,
      );
    });

    // ------------------------------------------------------------------
    // loginWithJwt
    // ------------------------------------------------------------------

    group('loginWithJwt', () {
      test('logs in a stale cached client and returns its user ID', () async {
        final mockClient = MockMatrixClient();
        when(() => mockClient.accessToken).thenReturn(null);
        when(() => mockClient.userID).thenReturn(_matrixUserId);
        final loginResponse = matrix.LoginResponse(
          userId: _matrixUserId,
          accessToken: 'token',
          deviceId: 'device',
          wellKnown: null,
          expiresInMs: null,
          refreshToken: null,
        );
        when(
          () => mockClient.login(
            MatrixSessionManager.jwtLoginType,
            token: _testJwt,
          ),
        ).thenAnswer((_) async => loginResponse);

        cache.seed(_testDid, mockClient);

        final userId = await manager.loginWithJwt(jwt: _testJwt, did: _testDid);
        expect(userId, equals(_matrixUserId));
        verify(
          () => mockClient.login(
            MatrixSessionManager.jwtLoginType,
            token: _testJwt,
          ),
        ).called(1);
      });

      test(
        'short-circuits and skips login when cached token is fresh',
        () async {
          final mockClient = _validClient();
          when(() => mockClient.userID).thenReturn(_matrixUserId);
          cache.seed(_testDid, mockClient);

          final userId = await manager.loginWithJwt(
            jwt: _testJwt,
            did: _testDid,
          );

          expect(userId, equals(_matrixUserId));
          verifyNever(
            () => mockClient.login(any(), token: any(named: 'token')),
          );
        },
      );

      test('deduplicates concurrent logins for the same DID', () async {
        final mockClient = MockMatrixClient();
        String? accessToken;
        when(() => mockClient.accessToken).thenAnswer((_) => accessToken);
        when(() => mockClient.userID).thenReturn(_matrixUserId);
        final loginResponse = matrix.LoginResponse(
          userId: _matrixUserId,
          accessToken: 'token',
          deviceId: 'device',
          wellKnown: null,
          expiresInMs: null,
          refreshToken: null,
        );
        var loginCalls = 0;
        when(
          () => mockClient.login(
            MatrixSessionManager.jwtLoginType,
            token: _testJwt,
          ),
        ).thenAnswer((_) async {
          loginCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          accessToken = 'token';
          return loginResponse;
        });

        cache.seed(_testDid, mockClient);

        final results = await Future.wait([
          manager.loginWithJwt(jwt: _testJwt, did: _testDid),
          manager.loginWithJwt(jwt: _testJwt, did: _testDid),
        ]);

        expect(results, [_matrixUserId, _matrixUserId]);
        expect(loginCalls, 1);
      });

      test('throws MatrixServiceException when login call fails', () async {
        final mockClient = MockMatrixClient();
        when(() => mockClient.accessToken).thenReturn(null);
        when(
          () => mockClient.login(any(), token: any(named: 'token')),
        ).thenThrow(Exception('network error'));

        cache.seed(_testDid, mockClient);

        expect(
          () => manager.loginWithJwt(jwt: _testJwt, did: _testDid),
          throwsA(isA<MatrixServiceException>()),
        );
      });

      test('evicts client from cache when login fails', () async {
        final mockClient = MockMatrixClient();
        when(() => mockClient.accessToken).thenReturn(null);
        when(
          () => mockClient.login(any(), token: any(named: 'token')),
        ).thenThrow(Exception('fail'));

        cache.seed(_testDid, mockClient);

        await expectLater(
          () => manager.loginWithJwt(jwt: _testJwt, did: _testDid),
          throwsA(isA<MatrixServiceException>()),
        );

        expect(cache.get(did: _testDid), isNull);
      });
    });

    // ------------------------------------------------------------------
    // getAuthenticatedClient
    // ------------------------------------------------------------------

    group('getAuthenticatedClient', () {
      test('returns null when no session exists', () async {
        expect(await manager.getAuthenticatedClient(_testDid), isNull);
      });

      test('returns null when access token is null', () async {
        cache.seed(_testDid, _unauthenticatedClient());

        expect(await manager.getAuthenticatedClient(_testDid), isNull);
      });

      test('returns client directly when token is not expiring soon', () async {
        final client = _validClient();
        cache.seed(_testDid, client);

        final result = await manager.getAuthenticatedClient(_testDid);
        expect(result, same(client));
        verifyNever(client.refreshAccessToken);
      });

      test(
        'returns client after successful token refresh when expiring soon',
        () async {
          final client = _expiringSoonClient();
          when(client.refreshAccessToken).thenAnswer((_) async {});
          cache.seed(_testDid, client);

          final result = await manager.getAuthenticatedClient(_testDid);
          expect(result, same(client));
          verify(client.refreshAccessToken).called(1);
        },
      );

      test('returns null and evicts client when refresh fails', () async {
        final client = _expiringSoonClient();
        when(client.refreshAccessToken).thenThrow(Exception('refresh failed'));
        cache.seed(_testDid, client);

        expect(await manager.getAuthenticatedClient(_testDid), isNull);

        expect(
          cache.get(did: _testDid),
          isNull,
          reason: 'stale client must be evicted after failed refresh',
        );
      });

      test('token without expiry is never considered expiring soon', () async {
        final client = MockMatrixClient();
        when(() => client.accessToken).thenReturn('no-expiry-token');
        when(() => client.accessTokenExpiresAt).thenReturn(null);
        cache.seed(_testDid, client);

        final result = await manager.getAuthenticatedClient(_testDid);
        expect(result, same(client));
        verifyNever(client.refreshAccessToken);
      });
    });

    // ------------------------------------------------------------------
    // deriveUserId
    // ------------------------------------------------------------------

    group('deriveUserId', () {
      test('produces deterministic Matrix user IDs', () {
        const did = 'did:test:alice';
        const server = 'matrix.example.com';

        final id1 = manager.deriveUserId(did, server);
        final id2 = manager.deriveUserId(did, server);

        expect(id1, equals(id2));
        expect(id1, startsWith('@'));
        expect(id1, endsWith(':$server'));
      });

      test('produces different IDs for different DIDs', () {
        const server = 'matrix.example.com';
        final id1 = manager.deriveUserId('did:test:alice', server);
        final id2 = manager.deriveUserId('did:test:bob', server);
        expect(id1, isNot(equals(id2)));
      });

      test('produces different IDs for different servers', () {
        const did = 'did:test:alice';
        final id1 = manager.deriveUserId(did, 'server-a.com');
        final id2 = manager.deriveUserId(did, 'server-b.com');
        expect(id1, isNot(equals(id2)));
      });
    });
  });

  // =========================================================================
  // MatrixService
  // =========================================================================

  group('MatrixService', () {
    late MockControlPlaneSDK controlPlane;
    late MockMatrixSessionManager sessionManager;
    late MockDidManager didManager;
    late MockDidDocument didDocument;
    late MatrixService service;

    setUp(() {
      controlPlane = MockControlPlaneSDK();
      sessionManager = MockMatrixSessionManager();
      didManager = MockDidManager();
      didDocument = MockDidDocument();

      when(() => didDocument.id).thenReturn(_testDid);
      when(didManager.getDidDocument).thenAnswer((_) async => didDocument);
      when(() => sessionManager.homeserver).thenReturn(_testHomeserver);

      service = MatrixService(
        config: _fakeConfig(),
        controlPlaneSDK: controlPlane,
        logger: _NoOpLogger(),
        sessionManager: sessionManager,
      );
    });

    // ------------------------------------------------------------------
    // loginWithDid
    // ------------------------------------------------------------------

    group('loginWithDid', () {
      test('fetches a JWT from the control plane and logs in', () async {
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => null);
        final tokenOutput = _stubMatrixToken(controlPlane, didManager);
        when(
          () => sessionManager.loginWithJwt(
            jwt: tokenOutput.token.toJwt(),
            did: _testDid,
          ),
        ).thenAnswer((_) async => _matrixUserId);

        final userId = await service.loginWithDid(didManager);
        expect(userId, equals(_matrixUserId));
      });
    });

    // ------------------------------------------------------------------
    // createRoom
    // ------------------------------------------------------------------

    group('createRoom', () {
      test('returns room ID when session is valid', () async {
        final client = MockMatrixClient();
        when(() => client.userID).thenReturn(_matrixUserId);
        when(() => client.encryptionEnabled).thenReturn(true);
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(
          () => client.createRoom(
            roomAliasName: any(named: 'roomAliasName'),
            invite: any(named: 'invite'),
            initialState: any(named: 'initialState'),
          ),
        ).thenAnswer((_) async => _testRoomId);
        when(
          () => sessionManager.deriveUserId(any(), any()),
        ).thenReturn('@invitee:matrix.example.com');

        final roomId = await service.createRoom(
          didManager: didManager,
          channelDid: 'did:test:alice',
          otherPartyChannelDid: 'did:test:bob',
          inviteUsers: ['did:test:bob'],
        );
        expect(roomId, equals(_testRoomId));
      });

      test('re-authenticates and retries when session is expired', () async {
        final client = MockMatrixClient();
        when(() => client.userID).thenReturn(_matrixUserId);
        when(() => client.encryptionEnabled).thenReturn(true);

        // Cache misses until loginWithJwt populates a session.
        var loggedIn = false;
        when(() => sessionManager.getAuthenticatedClient(_testDid)).thenAnswer((
          _,
        ) async {
          if (!loggedIn) return null;
          return client;
        });

        final tokenOutput = _stubMatrixToken(controlPlane, didManager);
        when(
          () => sessionManager.loginWithJwt(
            jwt: tokenOutput.token.toJwt(),
            did: _testDid,
          ),
        ).thenAnswer((_) async {
          loggedIn = true;
          return _matrixUserId;
        });

        when(
          () => client.createRoom(
            roomAliasName: any(named: 'roomAliasName'),
            invite: any(named: 'invite'),
            initialState: any(named: 'initialState'),
          ),
        ).thenAnswer((_) async => _testRoomId);
        when(
          () => sessionManager.deriveUserId(any(), any()),
        ).thenReturn('@invitee:matrix.example.com');

        final roomId = await service.createRoom(
          didManager: didManager,
          channelDid: 'did:test:alice',
          otherPartyChannelDid: 'did:test:bob',
        );
        expect(roomId, equals(_testRoomId));
        verify(
          () => sessionManager.loginWithJwt(
            jwt: any(named: 'jwt'),
            did: any(named: 'did'),
          ),
        ).called(1);
      });

      test('maps invite DIDs to Matrix user IDs', () async {
        final client = MockMatrixClient();
        when(() => client.userID).thenReturn(_matrixUserId);
        when(() => client.encryptionEnabled).thenReturn(true);
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(
          () =>
              sessionManager.deriveUserId('did:test:bob', _testHomeserver.host),
        ).thenReturn('@bob-hash:matrix.example.com');
        when(
          () => client.createRoom(
            roomAliasName: any(named: 'roomAliasName'),
            invite: ['@bob-hash:matrix.example.com'],
            initialState: any(named: 'initialState'),
          ),
        ).thenAnswer((_) async => _testRoomId);

        await service.createRoom(
          didManager: didManager,
          channelDid: 'did:test:alice',
          otherPartyChannelDid: 'did:test:bob',
          inviteUsers: ['did:test:bob'],
        );

        verify(
          () => client.createRoom(
            roomAliasName: any(named: 'roomAliasName', that: startsWith('mp_')),
            invite: ['@bob-hash:matrix.example.com'],
            initialState: any(named: 'initialState'),
          ),
        ).called(1);
      });

      test(
        'requests E2EE on new rooms via m.room.encryption initial state',
        () async {
          final client = MockMatrixClient();
          when(() => client.userID).thenReturn(_matrixUserId);
          when(() => client.encryptionEnabled).thenReturn(true);
          when(
            () => sessionManager.getAuthenticatedClient(_testDid),
          ).thenAnswer((_) async => client);
          when(
            () => sessionManager.deriveUserId(any(), any()),
          ).thenReturn(_matrixUserId);
          when(
            () => client.createRoom(
              roomAliasName: any(named: 'roomAliasName'),
              invite: any(named: 'invite'),
              initialState: any(named: 'initialState'),
            ),
          ).thenAnswer((_) async => _testRoomId);

          await service.createRoom(
            didManager: didManager,
            channelDid: 'did:test:alice',
            otherPartyChannelDid: 'did:test:bob',
          );

          final captured =
              verify(
                    () => client.createRoom(
                      roomAliasName: any(named: 'roomAliasName'),
                      invite: any(named: 'invite'),
                      initialState: captureAny(named: 'initialState'),
                    ),
                  ).captured.single
                  as List<matrix.StateEvent>;
          expect(captured, hasLength(1));
          expect(captured.single.type, matrix.EventTypes.Encryption);
          expect(
            captured.single.content['algorithm'],
            matrix.Client.supportedGroupEncryptionAlgorithms.first,
          );
        },
      );

      test('throws StateError when client encryption is disabled', () async {
        final client = MockMatrixClient();
        when(() => client.userID).thenReturn(_matrixUserId);
        when(() => client.encryptionEnabled).thenReturn(false);
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(
          () => sessionManager.deriveUserId(any(), any()),
        ).thenReturn(_matrixUserId);

        expect(
          () => service.createRoom(
            didManager: didManager,
            channelDid: 'did:test:alice',
          ),
          throwsStateError,
        );
      });

      test('throws MatrixAuthException when loginWithDid succeeds but the '
          'session is unavailable', () async {
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => null);
        final tokenOutput = _stubMatrixToken(controlPlane, didManager);
        when(
          () => sessionManager.loginWithJwt(
            jwt: tokenOutput.token.toJwt(),
            did: _testDid,
          ),
        ).thenAnswer((_) async => _matrixUserId);

        expect(
          () => service.createRoom(
            didManager: didManager,
            channelDid: 'did:test:alice',
          ),
          throwsA(isA<MatrixAuthException>()),
        );
      });
    });

    // ------------------------------------------------------------------
    // joinRoom
    // ------------------------------------------------------------------

    group('joinChannelRoom', () {
      test('joins the room via derived alias when session is valid', () async {
        final client = MockMatrixClient();
        when(() => client.userID).thenReturn(_matrixUserId);
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(() => client.joinRoom(any())).thenAnswer((_) async => _testRoomId);

        await service.joinChannelRoom(
          didManager: didManager,
          channelDid: 'did:test:alice',
          otherPartyChannelDid: 'did:test:bob',
        );

        verify(() => client.joinRoom(any(that: startsWith('#mp_')))).called(1);
      });

      test('re-authenticates and retries when session is expired', () async {
        final client = MockMatrixClient();
        when(() => client.userID).thenReturn(_matrixUserId);

        var loggedIn = false;
        when(() => sessionManager.getAuthenticatedClient(_testDid)).thenAnswer((
          _,
        ) async {
          if (!loggedIn) return null;
          return client;
        });

        final tokenOutput = _stubMatrixToken(controlPlane, didManager);
        when(
          () => sessionManager.loginWithJwt(
            jwt: tokenOutput.token.toJwt(),
            did: _testDid,
          ),
        ).thenAnswer((_) async {
          loggedIn = true;
          return _matrixUserId;
        });

        when(() => client.joinRoom(any())).thenAnswer((_) async => _testRoomId);

        await service.joinChannelRoom(
          didManager: didManager,
          channelDid: 'did:test:alice',
          otherPartyChannelDid: 'did:test:bob',
        );

        verify(() => client.joinRoom(any(that: startsWith('#mp_')))).called(1);
        verify(
          () => sessionManager.loginWithJwt(
            jwt: any(named: 'jwt'),
            did: any(named: 'did'),
          ),
        ).called(1);
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Stubs [ControlPlaneSDK.execute] for [MatrixTokenCommand] and returns the
/// mocked [MatrixTokenCommandOutput].
MatrixTokenCommandOutput _stubMatrixToken(
  MockControlPlaneSDK controlPlane,
  MockDidManager didManager,
) {
  final token = _FakeMatrixLoginToken();
  final output = _FakeMatrixTokenOutput(token);
  when(
    () => controlPlane.execute<MatrixTokenCommandOutput>(
      any(that: isA<MatrixTokenCommand>()),
    ),
  ).thenAnswer((_) async => output);
  return output;
}

class _FakeMatrixLoginToken extends Fake implements MatrixLoginToken {
  @override
  String toJwt() => _testJwt;
}

class _FakeMatrixTokenOutput extends Fake implements MatrixTokenCommandOutput {
  _FakeMatrixTokenOutput(this.token);

  @override
  final MatrixLoginToken token;
}

class _NoOpDatabaseFactory implements MatrixDatabaseFactory {
  const _NoOpDatabaseFactory();

  @override
  Future<matrix.DatabaseApi?> openDatabase(MatrixDatabaseContext context) =>
      Future.value(null);
}

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
