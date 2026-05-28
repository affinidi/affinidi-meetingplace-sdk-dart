import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_auth_exception.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_client_cache.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_config.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_service.dart';
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

/// A [MatrixClientCache] that accepts pre-seeded [matrix.Client] entries
/// without going through `MatrixClient.init`.
class _FakeClientCache extends MatrixClientCache {
  _FakeClientCache()
    : super(homeserver: Uri.parse('https://matrix.example.com'));

  final Map<String, matrix.Client> _clients = {};

  void seed(String did, matrix.Client client) => _clients[did] = client;

  @override
  matrix.Client? get({required String did}) => _clients[did];

  @override
  matrix.Client add({required String did, required matrix.Client client}) {
    _clients[did] = client;
    return client;
  }

  @override
  void remove({required String did}) => _clients.remove(did);

  @override
  void dispose() => _clients.clear();
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
  });

  // =========================================================================
  // MatrixSessionManager
  // =========================================================================

  group('MatrixSessionManager', () {
    late _FakeClientCache cache;
    late MatrixSessionManager manager;

    setUp(() {
      cache = _FakeClientCache();
      manager = MatrixSessionManager(config: _fakeConfig(), clientCache: cache);
    });

    // ------------------------------------------------------------------
    // loginWithJwt
    // ------------------------------------------------------------------

    group('loginWithJwt', () {
      test('creates a new client and returns the Matrix user ID', () async {
        final mockClient = MockMatrixClient();
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
      });

      test('throws MatrixServiceException when login call fails', () async {
        final mockClient = MockMatrixClient();
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
      test('throws MatrixAuthException when no session exists', () {
        expect(
          () => manager.getAuthenticatedClient(_testDid),
          throwsA(isA<MatrixAuthException>()),
        );
      });

      test('throws MatrixAuthException when access token is null', () {
        cache.seed(_testDid, _unauthenticatedClient());

        expect(
          () => manager.getAuthenticatedClient(_testDid),
          throwsA(isA<MatrixAuthException>()),
        );
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

      test(
        'throws MatrixAuthException and evicts client when refresh fails',
        () async {
          final client = _expiringSoonClient();
          when(
            client.refreshAccessToken,
          ).thenThrow(Exception('refresh failed'));
          cache.seed(_testDid, client);

          await expectLater(
            () => manager.getAuthenticatedClient(_testDid),
            throwsA(isA<MatrixAuthException>()),
          );

          expect(
            cache.get(did: _testDid),
            isNull,
            reason: 'stale client must be evicted after failed refresh',
          );
        },
      );

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
    // dispose
    // ------------------------------------------------------------------

    test('dispose clears the client cache', () {
      cache.seed(_testDid, _validClient());
      manager.dispose();
      expect(cache.get(did: _testDid), isNull);
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
        sessionManager: sessionManager,
      );
    });

    // ------------------------------------------------------------------
    // loginWithDid
    // ------------------------------------------------------------------

    group('loginWithDid', () {
      test('fetches a JWT from the control plane and logs in', () async {
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
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(
          () => client.createRoom(
            roomAliasName: any(named: 'roomAliasName'),
            invite: any(named: 'invite'),
          ),
        ).thenAnswer((_) async => _testRoomId);
        when(
          () => sessionManager.deriveUserId(any(), any()),
        ).thenReturn('@invitee:matrix.example.com');

        final roomId = await service.createRoom(
          didManager: didManager,
          channelDid: 'did:test:alice', otherPartyChannelDid: 'did:test:bob',
          inviteUsers: ['did:test:bob'],
        );
        expect(roomId, equals(_testRoomId));
      });

      test('re-authenticates and retries when session is expired', () async {
        final client = MockMatrixClient();

        // First call throws; second succeeds after re-auth.
        var callCount = 0;
        when(() => sessionManager.getAuthenticatedClient(_testDid)).thenAnswer((
          _,
        ) async {
          callCount++;
          if (callCount == 1) throw const MatrixAuthException();
          return client;
        });

        final tokenOutput = _stubMatrixToken(controlPlane, didManager);
        when(
          () => sessionManager.loginWithJwt(
            jwt: tokenOutput.token.toJwt(),
            did: _testDid,
          ),
        ).thenAnswer((_) async => _matrixUserId);

        when(
          () => client.createRoom(
            roomAliasName: any(named: 'roomAliasName'),
            invite: any(named: 'invite'),
          ),
        ).thenAnswer((_) async => _testRoomId);
        when(
          () => sessionManager.deriveUserId(any(), any()),
        ).thenReturn('@invitee:matrix.example.com');

        final roomId = await service.createRoom(
          didManager: didManager,
          channelDid: 'did:test:alice', otherPartyChannelDid: 'did:test:bob',
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
          ),
        ).thenAnswer((_) async => _testRoomId);

        await service.createRoom(
          didManager: didManager,
          channelDid: 'did:test:alice', otherPartyChannelDid: 'did:test:bob',
          inviteUsers: ['did:test:bob'],
        );

        verify(
          () => client.createRoom(
            roomAliasName: any(
              named: 'roomAliasName',
              that: startsWith('mp_'),
            ),
            invite: ['@bob-hash:matrix.example.com'],
          ),
        ).called(1);
      });
    });

    // ------------------------------------------------------------------
    // joinRoom
    // ------------------------------------------------------------------

    group('joinChannelRoom', () {
      test('joins the room via derived alias when session is valid', () async {
        final client = MockMatrixClient();
        when(
          () => sessionManager.getAuthenticatedClient(_testDid),
        ).thenAnswer((_) async => client);
        when(
          () => client.joinRoom(any()),
        ).thenAnswer((_) async => _testRoomId);

        await service.joinChannelRoom(
          didManager: didManager,
          channelDid: 'did:test:alice',
          otherPartyChannelDid: 'did:test:bob',
        );

        verify(() => client.joinRoom(any(that: startsWith('#mp_')))).called(1);
      });

      test('re-authenticates and retries when session is expired', () async {
        final client = MockMatrixClient();

        var callCount = 0;
        when(() => sessionManager.getAuthenticatedClient(_testDid)).thenAnswer((
          _,
        ) async {
          callCount++;
          if (callCount == 1) throw const MatrixAuthException();
          return client;
        });

        final tokenOutput = _stubMatrixToken(controlPlane, didManager);
        when(
          () => sessionManager.loginWithJwt(
            jwt: tokenOutput.token.toJwt(),
            did: _testDid,
          ),
        ).thenAnswer((_) async => _matrixUserId);

        when(
          () => client.joinRoom(any()),
        ).thenAnswer((_) async => _testRoomId);

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
    // dispose
    // ------------------------------------------------------------------

    test('dispose delegates to session manager', () {
      when(() => sessionManager.dispose()).thenReturn(null);
      service.dispose();
      verify(() => sessionManager.dispose()).called(1);
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
