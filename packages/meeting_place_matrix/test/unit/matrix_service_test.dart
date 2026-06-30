import 'dart:async';

import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix/src/voip/models/voip_id.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/matrix_client_cache.dart';
import 'package:meeting_place_matrix/src/matrix_session_manager.dart';
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

class MockMatrixRoom extends Mock implements matrix.Room {}

class MockMatrixSessionManager extends Mock implements MatrixSessionManager {}

class MockVoIP extends Mock implements matrix.VoIP {}

class MockGroupCallSession extends Mock implements matrix.GroupCallSession {}

class MockWebRTCDelegate extends Mock implements matrix.WebRTCDelegate {}

class FakeMatrixTokenCommand extends Fake implements MatrixTokenCommand {}

class FakeStateEvent extends Fake implements matrix.StateEvent {}

class FakeSyncUpdate extends Fake implements matrix.SyncUpdate {}

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
  deviceId: 'TESTDEVICEID',
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
    registerFallbackValue(matrix.Direction.b);
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
        when(
          () => mockClient.init(waitForFirstSync: false),
        ).thenAnswer((_) async {});
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
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer((_) async => loginResponse);

        cache.seed(_testDid, mockClient);

        final userId = await manager.loginWithJwt(jwt: _testJwt, did: _testDid);
        expect(userId, equals(_matrixUserId));
        verify(
          () => mockClient.login(
            MatrixSessionManager.jwtLoginType,
            token: _testJwt,
            deviceId: any(named: 'deviceId'),
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
        when(
          () => mockClient.init(waitForFirstSync: false),
        ).thenAnswer((_) async {});
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
            deviceId: any(named: 'deviceId'),
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
          () => mockClient.init(waitForFirstSync: false),
        ).thenAnswer((_) async {});
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
          () => mockClient.init(waitForFirstSync: false),
        ).thenAnswer((_) async {});
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

      test(
        'restores fresh session from persistent DB without calling login',
        () async {
          final mockClient = MockMatrixClient();
          var initialized = false;
          when(
            () => mockClient.accessToken,
          ).thenAnswer((_) => initialized ? 'restored-token' : null);
          when(() => mockClient.accessTokenExpiresAt).thenAnswer(
            (_) => initialized
                ? DateTime.now().add(const Duration(hours: 1))
                : null,
          );
          when(() => mockClient.userID).thenReturn(_matrixUserId);
          when(() => mockClient.init(waitForFirstSync: false)).thenAnswer((
            _,
          ) async {
            initialized = true;
          });
          cache.seed(_testDid, mockClient);

          final userId = await manager.loginWithJwt(
            jwt: _testJwt,
            did: _testDid,
          );

          expect(userId, equals(_matrixUserId));
          verify(() => mockClient.init(waitForFirstSync: false)).called(1);
          verifyNever(
            () => mockClient.login(any(), token: any(named: 'token')),
          );
        },
      );

      test(
        'refreshes stale token restored from persistent DB without login',
        () async {
          final mockClient = MockMatrixClient();
          var initialized = false;
          when(
            () => mockClient.accessToken,
          ).thenAnswer((_) => initialized ? 'stale-token' : null);
          when(() => mockClient.accessTokenExpiresAt).thenAnswer(
            (_) => initialized
                ? DateTime.now().add(const Duration(seconds: 30))
                : null,
          );
          when(() => mockClient.userID).thenReturn(_matrixUserId);
          when(() => mockClient.init(waitForFirstSync: false)).thenAnswer((
            _,
          ) async {
            initialized = true;
          });
          when(mockClient.refreshAccessToken).thenAnswer((_) async {});
          cache.seed(_testDid, mockClient);

          final userId = await manager.loginWithJwt(
            jwt: _testJwt,
            did: _testDid,
          );

          expect(userId, equals(_matrixUserId));
          verify(mockClient.refreshAccessToken).called(1);
          verifyNever(
            () => mockClient.login(any(), token: any(named: 'token')),
          );
        },
      );

      test(
        'falls through to JWT login when refresh fails after DB restore',
        () async {
          final mockClient = MockMatrixClient();
          var initialized = false;
          when(
            () => mockClient.accessToken,
          ).thenAnswer((_) => initialized ? 'stale-token' : null);
          when(() => mockClient.accessTokenExpiresAt).thenAnswer(
            (_) => initialized
                ? DateTime.now().add(const Duration(seconds: 30))
                : null,
          );
          when(() => mockClient.userID).thenReturn(_matrixUserId);
          when(() => mockClient.init(waitForFirstSync: false)).thenAnswer((
            _,
          ) async {
            initialized = true;
          });
          when(
            mockClient.refreshAccessToken,
          ).thenThrow(Exception('refresh failed'));
          final loginResponse = matrix.LoginResponse(
            userId: _matrixUserId,
            accessToken: 'new-token',
            deviceId: 'device',
            wellKnown: null,
            expiresInMs: null,
            refreshToken: null,
          );
          when(
            () => mockClient.login(
              MatrixSessionManager.jwtLoginType,
              token: _testJwt,
              deviceId: any(named: 'deviceId'),
            ),
          ).thenAnswer((_) async => loginResponse);
          cache.seed(_testDid, mockClient);

          final userId = await manager.loginWithJwt(
            jwt: _testJwt,
            did: _testDid,
          );

          expect(userId, equals(_matrixUserId));
          verify(mockClient.refreshAccessToken).called(1);
          verify(
            () => mockClient.login(
              MatrixSessionManager.jwtLoginType,
              token: _testJwt,
              deviceId: any(named: 'deviceId'),
            ),
          ).called(1);
        },
      );

      test('disables background sync after login', () async {
        final mockClient = MockMatrixClient();
        when(() => mockClient.accessToken).thenReturn(null);
        when(() => mockClient.userID).thenReturn(_matrixUserId);
        when(
          () => mockClient.init(waitForFirstSync: false),
        ).thenAnswer((_) async {});
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
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer((_) async => loginResponse);

        cache.seed(_testDid, mockClient);

        await manager.loginWithJwt(
          jwt: _testJwt,
          did: _testDid,
          loginSyncGracePeriod: const Duration(milliseconds: 20),
        );

        // backgroundSync = false must NOT be set synchronously right after
        // login — it fires after the post-login linger window.
        verifyNever(() => mockClient.backgroundSync = false);

        await Future<void>.delayed(const Duration(milliseconds: 60));

        verify(() => mockClient.backgroundSync = false).called(1);
      });

      test(
        'keepSyncActiveAfterLogin: sync is never disabled after login',
        () async {
          final keepActiveCache = _FakeClientCache();
          final keepActiveManager = MatrixSessionManager(
            config: _fakeConfig(),
            logger: _NoOpLogger(),
            clientCache: keepActiveCache,
          );
          final mockClient = MockMatrixClient();
          when(() => mockClient.accessToken).thenReturn(null);
          when(() => mockClient.userID).thenReturn(_matrixUserId);
          when(
            () => mockClient.init(waitForFirstSync: false),
          ).thenAnswer((_) async {});
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
              deviceId: any(named: 'deviceId'),
            ),
          ).thenAnswer((_) async => loginResponse);

          keepActiveCache.seed(_testDid, mockClient);

          await keepActiveManager.loginWithJwt(
            jwt: _testJwt,
            did: _testDid,
            keepSyncActiveAfterLogin: true,
          );

          await Future<void>.delayed(const Duration(milliseconds: 60));

          verifyNever(() => mockClient.backgroundSync = false);

          await keepActiveManager.dispose();
        },
      );
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
    // ------------------------------------------------------------------
    // activateSync / deactivateSync
    // ------------------------------------------------------------------

    group('activateSync / deactivateSync', () {
      test('first activation enables background sync', () {
        final client = MockMatrixClient();
        manager.activateSync(_testDid, client);
        verify(() => client.backgroundSync = true).called(1);
      });

      test('subsequent activations do not toggle sync again', () {
        final client = MockMatrixClient();
        manager.activateSync(_testDid, client);
        manager.activateSync(_testDid, client);
        manager.activateSync(_testDid, client);
        verify(() => client.backgroundSync = true).called(1);
      });

      test('deactivating last subscription disables background sync', () {
        final client = MockMatrixClient();
        manager.activateSync(_testDid, client);
        manager.deactivateSync(_testDid, client);
        verify(() => client.backgroundSync = false).called(1);
      });

      test('deactivating with remaining subscriptions keeps sync enabled', () {
        final client = MockMatrixClient();
        manager.activateSync(_testDid, client);
        manager.activateSync(_testDid, client);
        manager.deactivateSync(_testDid, client);
        verifyNever(() => client.backgroundSync = false);
      });

      test('different DIDs are tracked independently', () {
        final clientA = MockMatrixClient();
        final clientB = MockMatrixClient();
        manager.activateSync('did:test:a', clientA);
        manager.activateSync('did:test:b', clientB);
        manager.deactivateSync('did:test:a', clientA);
        verify(() => clientA.backgroundSync = false).called(1);
        verifyNever(() => clientB.backgroundSync = false);
      });

      test(
        'replacement client is enabled when DID already has subscriptions',
        () {
          final oldClient = MockMatrixClient();
          final newClient = MockMatrixClient();

          manager.activateSync(_testDid, oldClient);
          manager.activateSync(_testDid, newClient);

          verify(() => oldClient.backgroundSync = true).called(1);
          verify(() => newClient.backgroundSync = true).called(1);
        },
      );

      test(
        '''deactivating an old replaced client does not disable replacement client''',
        () {
          final oldClient = MockMatrixClient();
          final newClient = MockMatrixClient();

          manager.activateSync(_testDid, oldClient);
          manager.activateSync(_testDid, newClient);
          manager.deactivateSync(_testDid, oldClient);

          verify(() => oldClient.backgroundSync = false).called(1);
          verifyNever(() => newClient.backgroundSync = false);
        },
      );

      test('keepSyncActive: true skips deactivation entirely', () {
        final client = MockMatrixClient();
        manager.activateSync(_testDid, client);
        manager.deactivateSync(_testDid, client, keepSyncActive: true);
        verifyNever(() => client.backgroundSync = false);
      });

      test(
        'linger: sync is disabled after the linger duration elapses',
        () async {
          final client = MockMatrixClient();
          manager.activateSync(_testDid, client);
          manager.deactivateSync(
            _testDid,
            client,
            lingerDuration: const Duration(milliseconds: 20),
          );

          // Immediately after deactivateSync, sync should NOT yet be disabled.
          verifyNever(() => client.backgroundSync = false);

          // After the linger window, sync should be disabled.
          await Future<void>.delayed(const Duration(milliseconds: 60));
          verify(() => client.backgroundSync = false).called(1);
        },
      );

      test(
        'linger: re-subscribing during linger window cancels deactivation',
        () async {
          final client = MockMatrixClient();
          manager.activateSync(_testDid, client);
          manager.deactivateSync(
            _testDid,
            client,
            lingerDuration: const Duration(milliseconds: 20),
          );

          // Re-subscribe before the linger expires.
          manager.activateSync(_testDid, client);

          await Future<void>.delayed(const Duration(milliseconds: 60));

          // backgroundSync should never have been set to false.
          verifyNever(() => client.backgroundSync = false);
        },
      );

      test(
        'linger: disposing manager cancels pending deactivation timer',
        () async {
          final client = MockMatrixClient();
          manager.activateSync(_testDid, client);
          manager.deactivateSync(
            _testDid,
            client,
            lingerDuration: const Duration(milliseconds: 20),
          );

          await manager.dispose();

          // Even after linger would have elapsed, no attempt to set
          // backgroundSync.
          await Future<void>.delayed(const Duration(milliseconds: 60));
          verifyNever(() => client.backgroundSync = false);
        },
      );
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
      when(() => sessionManager.serverName).thenReturn(_testHomeserver.host);

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
            powerLevelContentOverride: any(named: 'powerLevelContentOverride'),
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
            powerLevelContentOverride: any(named: 'powerLevelContentOverride'),
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
          () => sessionManager.deriveUserId(any(), any()),
        ).thenReturn(_matrixUserId);
        when(
          () =>
              sessionManager.deriveUserId('did:test:bob', _testHomeserver.host),
        ).thenReturn('@bob-hash:matrix.example.com');
        when(
          () => client.createRoom(
            roomAliasName: any(named: 'roomAliasName'),
            invite: ['@bob-hash:matrix.example.com'],
            initialState: any(named: 'initialState'),
            powerLevelContentOverride: any(named: 'powerLevelContentOverride'),
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
            powerLevelContentOverride: any(named: 'powerLevelContentOverride'),
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
              powerLevelContentOverride: any(
                named: 'powerLevelContentOverride',
              ),
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
                      powerLevelContentOverride: any(
                        named: 'powerLevelContentOverride',
                      ),
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

      test('throws exception when client encryption is disabled', () async {
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
          throwsA(
            isA<MatrixServiceException>().having(
              (e) => e.message,
              'message',
              contains('encryption is not enabled'),
            ),
          ),
        );
      });

      test('throws MatrixAuthException when loginWithDid succeeds but the '
          'session is unavailable', () async {
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => null);
        when(
          () => sessionManager.deriveUserId(any(), any()),
        ).thenReturn(_matrixUserId);
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
      test('returns room ID when room is encrypted', () async {
        final client = MockMatrixClient();
        final room = MockMatrixRoom();
        when(() => client.userID).thenReturn(_matrixUserId);
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(() => client.joinRoom(any())).thenAnswer((_) async => _testRoomId);
        when(() => client.getRoomById(_testRoomId)).thenReturn(room);
        when(() => room.encrypted).thenReturn(true);

        final roomId = await service.joinChannelRoom(
          didManager: didManager,
          channelDid: 'did:test:alice',
          otherPartyChannelDid: 'did:test:bob',
        );

        expect(roomId, equals(_testRoomId));
        verify(() => client.joinRoom(any(that: startsWith('#mp_')))).called(1);
      });

      test(
        'waits for sync and returns room ID when room appears after join',
        () async {
          final client = MockMatrixClient();
          final room = MockMatrixRoom();
          when(() => client.userID).thenReturn(_matrixUserId);
          when(
            () => sessionManager.getAuthenticatedClient(_testDid),
          ).thenAnswer((_) async => client);
          when(
            () => client.joinRoom(any()),
          ).thenAnswer((_) async => _testRoomId);
          // Room not available immediately; appears after sync.
          var syncCalled = false;
          when(() => client.getRoomById(_testRoomId)).thenAnswer((_) {
            return syncCalled ? room : null;
          });
          when(client.oneShotSync).thenAnswer((_) async {
            syncCalled = true;
          });
          when(() => room.encrypted).thenReturn(true);

          final roomId = await service.joinChannelRoom(
            didManager: didManager,
            channelDid: 'did:test:alice',
            otherPartyChannelDid: 'did:test:bob',
          );

          expect(roomId, equals(_testRoomId));
          verify(client.oneShotSync).called(1);
        },
      );

      test('throws StateError when joined room is not encrypted', () async {
        final client = MockMatrixClient();
        final room = MockMatrixRoom();
        when(() => client.userID).thenReturn(_matrixUserId);
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(() => client.joinRoom(any())).thenAnswer((_) async => _testRoomId);
        when(() => client.getRoomById(_testRoomId)).thenReturn(room);
        when(() => room.encrypted).thenReturn(false);

        expect(
          () => service.joinChannelRoom(
            didManager: didManager,
            channelDid: 'did:test:alice',
            otherPartyChannelDid: 'did:test:bob',
          ),
          throwsStateError,
        );
      });

      test(
        'throws StateError when room does not appear in sync after joining',
        () async {
          final client = MockMatrixClient();
          when(() => client.userID).thenReturn(_matrixUserId);
          when(
            () => sessionManager.getAuthenticatedClient(_testDid),
          ).thenAnswer((_) async => client);
          when(
            () => client.joinRoom(any()),
          ).thenAnswer((_) async => _testRoomId);
          when(() => client.getRoomById(_testRoomId)).thenReturn(null);
          when(client.oneShotSync).thenAnswer((_) async {});

          expect(
            () => service.joinChannelRoom(
              didManager: didManager,
              channelDid: 'did:test:alice',
              otherPartyChannelDid: 'did:test:bob',
            ),
            throwsStateError,
          );
        },
      );

      test('re-authenticates and retries when session is expired', () async {
        final client = MockMatrixClient();
        final room = MockMatrixRoom();
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
        when(() => client.getRoomById(_testRoomId)).thenReturn(room);
        when(() => room.encrypted).thenReturn(true);

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

    // ------------------------------------------------------------------
    // fetchRoomHistory
    // ------------------------------------------------------------------

    group('fetchRoomHistory', () {
      late MockMatrixClient client;
      late MockMatrixRoom room;

      setUp(() {
        client = MockMatrixClient();
        room = MockMatrixRoom();
        when(() => client.userID).thenReturn(_matrixUserId);
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(
          () => sessionManager.deriveUserId(any(), any()),
        ).thenReturn(_matrixUserId);
        when(
          () => room.requestHistory(
            historyCount: any(named: 'historyCount'),
            direction: any<matrix.Direction>(named: 'direction'),
          ),
        ).thenAnswer((_) async => 0);
        when(
          () => room.getTimeline(limit: any(named: 'limit')),
        ).thenAnswer((_) async => _FakeTimeline());
      });

      test('returns empty list when room is not found', () async {
        when(() => client.getRoomById(_testRoomId)).thenReturn(null);

        final result = await service.fetchRoomHistory(
          _testRoomId,
          didManager: didManager,
        );

        expect(result, isEmpty);
      });

      test('with sinceEventId: resolves context token, sets prev_batch and '
          'calls requestHistory forward', () async {
        const anchorEventId = r'$anchor-event';
        const paginationToken = 'fwd-token-123';

        when(() => client.getRoomById(_testRoomId)).thenReturn(room);
        when(
          () => client.getEventContext(_testRoomId, anchorEventId, limit: 0),
        ).thenAnswer((_) async => _FakeEventContext(end: paginationToken));

        await service.fetchRoomHistory(
          _testRoomId,
          didManager: didManager,
          since: anchorEventId,
        );

        verify(
          () => client.getEventContext(_testRoomId, anchorEventId, limit: 0),
        ).called(1);
        verify(() => room.prev_batch = paginationToken).called(1);
        verify(
          () => room.requestHistory(
            historyCount: any(named: 'historyCount'),
            direction: matrix.Direction.f,
          ),
        ).called(1);
        verify(() => room.getTimeline(limit: any(named: 'limit'))).called(1);
      });

      test('with sinceEventId and null context.end: skips setting prev_batch '
          'but still calls requestHistory forward', () async {
        const anchorEventId = r'$anchor-event';

        when(() => client.getRoomById(_testRoomId)).thenReturn(room);
        when(
          () => client.getEventContext(_testRoomId, anchorEventId, limit: 0),
        ).thenAnswer((_) async => _FakeEventContext(end: null));

        await service.fetchRoomHistory(
          _testRoomId,
          didManager: didManager,
          since: anchorEventId,
        );

        verifyNever(() => room.prev_batch = any());
        verify(
          () => room.requestHistory(
            historyCount: any(named: 'historyCount'),
            direction: matrix.Direction.f,
          ),
        ).called(1);
        verify(() => room.getTimeline(limit: any(named: 'limit'))).called(1);
      });

      test('without sinceEventId: calls requestHistory forward without '
          'getEventContext', () async {
        when(() => client.getRoomById(_testRoomId)).thenReturn(room);

        await service.fetchRoomHistory(_testRoomId, didManager: didManager);

        verifyNever(
          () =>
              client.getEventContext(any(), any(), limit: any(named: 'limit')),
        );
        verify(
          () => room.requestHistory(
            historyCount: any(named: 'historyCount'),
            direction: matrix.Direction.f,
          ),
        ).called(1);
        verify(() => room.getTimeline(limit: any(named: 'limit'))).called(1);
      });
    });

    // ------------------------------------------------------------------
    // sendRoomEvent
    // ------------------------------------------------------------------

    group('sendRoomEvent', () {
      test('throws StateError when room is not encrypted', () async {
        final client = MockMatrixClient();
        final room = MockMatrixRoom();
        when(() => client.userID).thenReturn(_matrixUserId);
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(
          () => sessionManager.deriveUserId(any(), any()),
        ).thenReturn(_matrixUserId);
        when(() => client.getRoomById(_testRoomId)).thenReturn(room);
        when(() => room.encrypted).thenReturn(false);
        when(client.oneShotSync).thenAnswer((_) async {});

        expect(
          () => service.sendRoomEvent(_testRoomId, 'com.example.message', {
            'body': 'hello',
          }, didManager: didManager),
          throwsStateError,
        );
      });

      test('sends event when room is encrypted', () async {
        final client = MockMatrixClient();
        final room = MockMatrixRoom();
        when(() => client.userID).thenReturn(_matrixUserId);
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(() => client.getRoomById(_testRoomId)).thenReturn(room);
        when(() => room.encrypted).thenReturn(true);
        when(
          () => room.sendEvent(any(), type: any(named: 'type')),
        ).thenAnswer((_) async => '\$eventId');
        when(
          () => sessionManager.deriveUserId(any(), any()),
        ).thenReturn(_matrixUserId);

        final eventId = await service.sendRoomEvent(
          _testRoomId,
          'com.example.message',
          {'body': 'hello'},
          didManager: didManager,
        );

        expect(eventId, equals('\$eventId'));
      });
    });

    // ------------------------------------------------------------------
    // getOpenIdToken
    // ------------------------------------------------------------------

    group('getOpenIdToken', () {
      test('returns OpenIdCredentials from the authenticated client', () async {
        final client = _validClient();
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);

        when(() => client.userID).thenReturn(_matrixUserId);

        final credentials = matrix.OpenIdCredentials.fromJson({
          'access_token': 'openid-token',
          'expires_in': 3600,
          'matrix_server_name': 'matrix.example.com',
          'token_type': 'Bearer',
        });
        when(
          () => client.requestOpenIdToken(_matrixUserId, {}),
        ).thenAnswer((_) async => credentials);

        final result = await service.getOpenIdToken(didManager);

        expect(result.accessToken, equals('openid-token'));
        expect(result.matrixServerName, equals('matrix.example.com'));
      });

      test('throws MatrixServiceException when client has no userID '
          'after ensureSession', () async {
        final client = _validClient();
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(() => client.userID).thenReturn(null);

        await expectLater(
          () => service.getOpenIdToken(didManager),
          throwsA(isA<MatrixServiceException>()),
        );
      });

      test('propagates MatrixAuthException when re-login also fails', () async {
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenThrow(const MatrixAuthException());

        _stubMatrixToken(controlPlane, didManager);

        when(
          () => sessionManager.loginWithJwt(
            jwt: any(named: 'jwt'),
            did: any(named: 'did'),
          ),
        ).thenAnswer((_) async => _matrixUserId);

        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenThrow(const MatrixAuthException());

        await expectLater(
          () => service.getOpenIdToken(didManager),
          throwsA(isA<MatrixAuthException>()),
        );
      });
    });

    // ------------------------------------------------------------------
    // VoIP / MatrixRTC
    // ------------------------------------------------------------------

    group('initializeVoIP', () {
      test('stores the VoIP instance for subsequent call operations', () {
        final voip = MockVoIP();

        // initializeVoIP is synchronous — no error means success.
        expect(() => service.initializeVoIP(voip), returnsNormally);
      });
    });

    group('localMatrixIdentity', () {
      test('returns userId:deviceId when session is active', () async {
        final client = MockMatrixClient();
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(() => client.userID).thenReturn('@alice:localhost');
        when(() => client.deviceID).thenReturn('DEVICEID');

        final identity = await service.ownMatrixIdentity(didManager);

        expect(identity, equals('@alice:localhost:DEVICEID'));
      });

      test('returns null when client has no userID', () async {
        final client = MockMatrixClient();
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(() => client.userID).thenReturn(null);
        when(() => client.deviceID).thenReturn('DEVICEID');

        final identity = await service.ownMatrixIdentity(didManager);

        expect(identity, isNull);
      });
    });

    group('startCall', () {
      test(
        'throws MatrixServiceException when VoIP is not initialized',
        () async {
          // No VoIP initialized.
          await expectLater(
            () => service.startCall(
              didManager: didManager,
              roomId: '!room:localhost',
              livekitServiceUrl: 'wss://lk.example.com',
              livekitAlias: 'test-alias',
            ),
            throwsA(
              isA<MatrixServiceException>().having(
                (e) => e.code,
                'code',
                MeetingPlaceCoreSDKErrorCode.matrixVoipNotInitialized,
              ),
            ),
          );
        },
      );

      test('throws MatrixServiceException when room is not found', () async {
        final client = MockMatrixClient();
        final voip = MockVoIP();
        service.initializeVoIP(voip);

        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(() => client.userID).thenReturn(_matrixUserId);
        when(() => client.getRoomById(any())).thenReturn(null);

        await expectLater(
          () => service.startCall(
            didManager: didManager,
            roomId: '!missing:localhost',
            livekitServiceUrl: 'wss://lk.example.com',
            livekitAlias: 'test-alias',
          ),
          throwsA(
            isA<MatrixServiceException>().having(
              (e) => e.code,
              'code',
              MeetingPlaceCoreSDKErrorCode.matrixRoomNotFound,
            ),
          ),
        );
      });
    });

    group('leaveCall', () {
      test('returns normally when VoIP is not initialized', () async {
        // No VoIP initialized — leaveCall should be a no-op, not throw.
        await expectLater(
          () => service.leaveCall(
            roomId: '!room:localhost',
            callId: '!room:localhost',
          ),
          returnsNormally,
        );
      });
    });

    group('hasActiveCallMembership', () {
      test('returns false when VoIP is not initialized', () async {
        final result = await service.hasActiveCallMembership(
          didManager: didManager,
          roomId: _testRoomId,
        );

        expect(result, isFalse);
      });

      test('returns false when the room is not found', () async {
        final client = MockMatrixClient();
        final voip = MockVoIP();
        service.initializeVoIP(voip);

        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(() => client.userID).thenReturn(_matrixUserId);
        when(() => client.getRoomById(any())).thenReturn(null);

        final result = await service.hasActiveCallMembership(
          didManager: didManager,
          roomId: _testRoomId,
        );

        expect(result, isFalse);
      });

      test('returns false when the room has no call memberships', () async {
        final client = MockMatrixClient();
        final voip = MockVoIP();
        final room = MockMatrixRoom();
        service.initializeVoIP(voip);

        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(() => client.userID).thenReturn(_matrixUserId);
        when(() => client.getRoomById(_testRoomId)).thenReturn(room);
        when(() => room.states).thenReturn({});

        final result = await service.hasActiveCallMembership(
          didManager: didManager,
          roomId: _testRoomId,
        );

        expect(result, isFalse);
      });
    });

    group('activeCallId', () {
      test('returns null when VoIP is not initialized', () async {
        final result = await service.activeCallId(
          didManager: didManager,
          roomId: _testRoomId,
        );

        expect(result, isNull);
      });

      test('returns null when the room is not found', () async {
        final client = MockMatrixClient();
        final voip = MockVoIP();
        service.initializeVoIP(voip);

        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(() => client.userID).thenReturn(_matrixUserId);
        when(() => client.getRoomById(any())).thenReturn(null);

        final result = await service.activeCallId(
          didManager: didManager,
          roomId: _testRoomId,
        );

        expect(result, isNull);
      });

      test('returns null when the room has no call memberships', () async {
        final client = MockMatrixClient();
        final voip = MockVoIP();
        final room = MockMatrixRoom();
        service.initializeVoIP(voip);

        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(() => client.userID).thenReturn(_matrixUserId);
        when(() => client.getRoomById(_testRoomId)).thenReturn(room);
        when(() => room.states).thenReturn({});

        final result = await service.activeCallId(
          didManager: didManager,
          roomId: _testRoomId,
        );

        expect(result, isNull);
      });
    });

    group('activateIncomingCall', () {
      test(
        'returns the group call already present in the room state',
        () async {
          final client = _validClient();
          when(() => client.userID).thenReturn(_matrixUserId);
          when(
            () => sessionManager.getAuthenticatedClient(_testDid),
          ).thenAnswer((_) async => client);

          final voip = MockVoIP();
          final session = MockGroupCallSession();
          when(() => session.groupCallId).thenReturn('call-1');
          when(() => voip.groupCalls).thenReturn({
            VoipId(roomId: _testRoomId, callId: 'call-1'): session,
          });
          service.initializeVoIP(voip);

          final result = await service.activateIncomingCall(
            didManager: didManager,
            delegate: MockWebRTCDelegate(),
            roomId: _testRoomId,
          );

          expect(result, same(session));
        },
      );

      test('resolves via onIncomingGroupCall when the group call arrives '
          'after VoIP creation', () async {
        final client = _validClient();
        when(() => client.userID).thenReturn(_matrixUserId);
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(() => client.getRoomById(any())).thenReturn(null);
        when(
          () => client.waitForRoomInSync(any(), join: any(named: 'join')),
        ).thenAnswer((_) async => FakeSyncUpdate());

        final voip = MockVoIP();
        final session = MockGroupCallSession();
        when(() => session.groupCallId).thenReturn('call-2');
        when(() => voip.groupCalls).thenReturn({});

        late final StreamController<matrix.GroupCallSession>
        groupCallController;
        groupCallController = StreamController<matrix.GroupCallSession>(
          onListen: () {
            when(() => voip.groupCalls).thenReturn({
              VoipId(roomId: _testRoomId, callId: 'call-2'): session,
            });
            groupCallController.add(session);
          },
        );
        when(() => voip.onIncomingGroupCall).thenReturn(groupCallController);

        service.initializeVoIP(voip);

        final result = await service.activateIncomingCall(
          didManager: didManager,
          delegate: MockWebRTCDelegate(),
          roomId: _testRoomId,
        );

        expect(result, same(session));
        await groupCallController.close();
      });

      test('activates a second incoming call on the cached VoIP without '
          're-listening to onIncomingGroupCall', () async {
        final client = _validClient();
        when(() => client.userID).thenReturn(_matrixUserId);
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(() => client.getRoomById(any())).thenReturn(null);
        when(
          () => client.waitForRoomInSync(any(), join: any(named: 'join')),
        ).thenAnswer((_) async => FakeSyncUpdate());

        final voip = MockVoIP();
        final firstSession = MockGroupCallSession();
        final secondSession = MockGroupCallSession();
        when(() => firstSession.groupCallId).thenReturn('call-a');
        when(() => secondSession.groupCallId).thenReturn('call-b');

        var groupCalls = <VoipId, matrix.GroupCallSession>{};
        when(() => voip.groupCalls).thenAnswer((_) => groupCalls);

        late final StreamController<matrix.GroupCallSession>
        groupCallController;
        groupCallController = StreamController<matrix.GroupCallSession>(
          onListen: () {
            groupCalls = {
              VoipId(roomId: _testRoomId, callId: 'call-a'): firstSession,
            };
            groupCallController.add(firstSession);
          },
        );
        when(() => voip.onIncomingGroupCall).thenReturn(groupCallController);

        service.initializeVoIP(voip);

        final first = await service.activateIncomingCall(
          didManager: didManager,
          delegate: MockWebRTCDelegate(),
          roomId: _testRoomId,
        );
        expect(first, same(firstSession));

        const secondRoomId = '!second-room:matrix.test';
        final secondFuture = service.activateIncomingCall(
          didManager: didManager,
          delegate: MockWebRTCDelegate(),
          roomId: secondRoomId,
        );

        await Future<void>.delayed(Duration.zero);
        groupCalls = {
          ...groupCalls,
          VoipId(roomId: secondRoomId, callId: 'call-b'): secondSession,
        };
        groupCallController.add(secondSession);

        expect(await secondFuture, same(secondSession));

        await groupCallController.close();
      });

      test('waits for the room to sync before resolving when the session '
          'has not loaded it yet', () async {
        final client = _validClient();
        when(() => client.userID).thenReturn(_matrixUserId);
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(() => client.getRoomById(any())).thenReturn(null);
        when(
          () => client.waitForRoomInSync(any(), join: any(named: 'join')),
        ).thenAnswer((_) async => FakeSyncUpdate());

        final voip = MockVoIP();
        final session = MockGroupCallSession();
        when(() => session.groupCallId).thenReturn('call-3');

        late final StreamController<matrix.GroupCallSession>
        groupCallController;
        groupCallController = StreamController<matrix.GroupCallSession>(
          onListen: () {
            when(() => voip.groupCalls).thenReturn({
              VoipId(roomId: _testRoomId, callId: 'call-3'): session,
            });
            groupCallController.add(session);
          },
        );
        when(() => voip.groupCalls).thenReturn({});
        when(() => voip.onIncomingGroupCall).thenReturn(groupCallController);

        service.initializeVoIP(voip);

        final result = await service.activateIncomingCall(
          didManager: didManager,
          delegate: MockWebRTCDelegate(),
          roomId: _testRoomId,
        );

        expect(result, same(session));
        verify(
          () => client.waitForRoomInSync(_testRoomId, join: true),
        ).called(1);
        await groupCallController.close();
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

class _FakeEventContext extends Fake implements matrix.EventContext {
  _FakeEventContext({this.end});

  @override
  final String? end;
}

class _FakeTimeline extends Fake implements matrix.Timeline {
  _FakeTimeline({List<matrix.Event> events = const []}) : _events = events;

  final List<matrix.Event> _events;

  @override
  List<matrix.Event> get events => _events;
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
