import 'dart:convert';

import 'package:test/test.dart';
import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';

void main() {
  group('VtaSessionManager', () {
    test('refreshes expired access token and updates bearer token', () async {
      final now = DateTime.utc(2026, 7, 1, 12);
      final transport = _FakeTransport(
        postHandler: (uri, headers, body) async {
          expect(uri.path, '/auth/refresh');
          final request = jsonDecode(body! as String) as Map<String, dynamic>;
          expect(
            request['type'],
            'https://trusttasks.org/spec/auth/refresh/0.1',
          );
          return VtaHttpResponse(statusCode: 200, body: '{"tt":"refresh"}');
        },
      );
      final client = VtaClient(
        baseUrl: 'https://example.com',
        transport: transport,
      );
      final protocol = _FakeProtocol(
        buildRefreshDocumentHandler: (_) async => jsonEncode({
          'id': 'urn:uuid:refresh',
          'type': 'https://trusttasks.org/spec/auth/refresh/0.1',
          'payload': {'refreshToken': 'refresh-1'},
        }),
        parseRefreshResponseHandler: (_) async => _authResult(
          accessToken: 'access-2',
          refreshToken: 'refresh-2',
          issuedAt: now,
        ),
      );
      final manager = VtaSessionManager(
        client: client,
        holderDid: 'did:key:zHolder',
        vtaDid: 'did:webvh:vta.example',
        protocol: protocol,
        clock: () => now,
        whoAmISyncPolicy: VtaWhoAmISyncPolicy.never,
      );

      manager.applyAuthenticateResult(
        _authResult(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          issuedAt: now.subtract(const Duration(minutes: 15)),
          expiresIn: 300,
        ),
      );

      final token = await manager.getValidAccessToken();
      expect(token, 'access-2');
      expect(client.authToken, 'access-2');
      expect(manager.tokens?.refreshToken, 'refresh-2');
    });

    test('single-flight refresh for concurrent callers', () async {
      final now = DateTime.utc(2026, 7, 1, 12);
      var refreshCalls = 0;
      final transport = _FakeTransport(
        postHandler: (uri, headers, body) async {
          if (uri.path == '/auth/refresh') {
            refreshCalls += 1;
            return VtaHttpResponse(statusCode: 200, body: '{"tt":"refresh"}');
          }
          throw StateError('Unexpected path ${uri.path}');
        },
      );
      final client = VtaClient(
        baseUrl: 'https://example.com',
        transport: transport,
      );
      final protocol = _FakeProtocol(
        buildRefreshDocumentHandler: (_) async => '{}',
        parseRefreshResponseHandler: (_) async => _authResult(
          accessToken: 'access-2',
          refreshToken: 'refresh-2',
          issuedAt: now,
        ),
      );
      final manager = VtaSessionManager(
        client: client,
        holderDid: 'did:key:zHolder',
        vtaDid: 'did:webvh:vta.example',
        protocol: protocol,
        clock: () => now,
        whoAmISyncPolicy: VtaWhoAmISyncPolicy.never,
      );

      manager.applyAuthenticateResult(
        _authResult(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          issuedAt: now.subtract(const Duration(minutes: 20)),
          expiresIn: 30,
        ),
      );

      final tokens = await Future.wait([
        manager.getValidAccessToken(),
        manager.getValidAccessToken(),
        manager.getValidAccessToken(),
      ]);

      expect(tokens, everyElement('access-2'));
      expect(refreshCalls, 1);
    });

    test('throws when refresh token is missing for expired session', () async {
      final now = DateTime.utc(2026, 7, 1, 12);
      final client = VtaClient(
        baseUrl: 'https://example.com',
        transport: _FakeTransport(),
      );
      final manager = VtaSessionManager(
        client: client,
        holderDid: 'did:key:zHolder',
        vtaDid: 'did:webvh:vta.example',
        protocol: _FakeProtocol(),
        clock: () => now,
        whoAmISyncPolicy: VtaWhoAmISyncPolicy.never,
      );

      manager.applyAuthenticateResult(
        _authResult(
          accessToken: 'access-1',
          refreshToken: null,
          issuedAt: now.subtract(const Duration(minutes: 20)),
          expiresIn: 60,
        ),
      );

      await expectLater(
        manager.getValidAccessToken(),
        throwsA(
          isA<VtaAuthException>().having(
            (error) => error.code,
            'code',
            'e.vta.auth.refresh_missing',
          ),
        ),
      );
      expect(client.authToken, isNull);
      expect(manager.tokens, isNull);
    });

    test('clears session when refresh is unauthorized', () async {
      final now = DateTime.utc(2026, 7, 1, 12);
      final transport = _FakeTransport(
        postHandler: (uri, headers, body) async {
          expect(uri.path, '/auth/refresh');
          return VtaHttpResponse(
            statusCode: 401,
            body: '{"error":"unauthorized"}',
          );
        },
      );
      final client = VtaClient(
        baseUrl: 'https://example.com',
        transport: transport,
      );
      final manager = VtaSessionManager(
        client: client,
        holderDid: 'did:key:zHolder',
        vtaDid: 'did:webvh:vta.example',
        protocol: _FakeProtocol(buildRefreshDocumentHandler: (_) async => '{}'),
        clock: () => now,
        whoAmISyncPolicy: VtaWhoAmISyncPolicy.never,
      );

      manager.applyAuthenticateResult(
        _authResult(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          issuedAt: now.subtract(const Duration(minutes: 20)),
          expiresIn: 60,
        ),
      );

      await expectLater(
        manager.getValidAccessToken(),
        throwsA(
          isA<VtaAuthException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
      expect(client.authToken, isNull);
      expect(manager.tokens, isNull);
      expect(manager.session, isNull);
    });
  });

  group('TrustTaskVtaAuthProtocol', () {
    test('builds canonical authenticate document with proof', () async {
      final protocol = TrustTaskVtaAuthProtocol(signer: const _StaticSigner());
      final document = await protocol.buildAuthenticateDocument(
        VtaAuthenticateRequest.create(
          holderDid: 'did:key:zHolder',
          vtaDid: 'did:webvh:vta.example',
          challenge: 'nonce-1',
          sessionId: 'sess-1',
          requestId: 'urn:uuid:test-auth',
          issuedAt: DateTime.utc(2026, 7, 1),
        ),
      );

      final json = jsonDecode(document) as Map<String, dynamic>;
      expect(json['type'], 'https://trusttasks.org/spec/auth/authenticate/0.1');
      expect(json['proof'], isA<Map<String, dynamic>>());
    });

    test('builds default refresh trust-task document', () async {
      final protocol = TrustTaskVtaAuthProtocol(
        authenticateProofRequirement: VtaProofRequirement.none,
        whoAmIProofRequirement: VtaProofRequirement.none,
      );

      final refresh = await protocol.buildRefreshDocument(
        VtaRefreshRequest.create(
          holderDid: 'did:key:zHolder',
          vtaDid: 'did:webvh:vta.example',
          refreshToken: 'refresh-1',
          scopes: const ['acl:read'],
          issuedAt: DateTime.utc(2026, 7, 1),
          requestId: 'urn:uuid:test-id',
        ),
      );
      final doc = jsonDecode(refresh) as Map<String, dynamic>;
      expect(doc['type'], 'https://trusttasks.org/spec/auth/refresh/0.1');
      expect(doc['id'], 'urn:uuid:test-id');
      expect(
        (doc['payload'] as Map<String, dynamic>)['refreshToken'],
        'refresh-1',
      );
    });

    test('throws parse error for malformed whoami payload', () async {
      final protocol = TrustTaskVtaAuthProtocol(
        authenticateProofRequirement: VtaProofRequirement.none,
        whoAmIProofRequirement: VtaProofRequirement.none,
      );

      await expectLater(
        protocol.parseWhoAmIResponse('{"payload":{"session":"bad"}}'),
        throwsA(isA<VtaParseException>()),
      );
    });
  });

  group('VtaConnectionCoordinator', () {
    test('reconnect retries transient transport failures', () async {
      var attempts = 0;
      final service = _FakeAuthService(
        reconnectHandler: ({purpose, scopes = const <String>[]}) async {
          attempts += 1;
          if (attempts < 3) {
            throw const VtaTransportException('transient');
          }
          return _authResult(
            accessToken: 'access-3',
            refreshToken: 'refresh-3',
            issuedAt: DateTime.utc(2026, 7, 1, 12),
          );
        },
      );

      final coordinator = VtaConnectionCoordinator(
        authService: service,
        sessionManager: service.sessionManager,
        reconnectPolicy: const VtaReconnectPolicy(
          maxAttempts: 3,
          initialBackoff: Duration.zero,
          maxBackoff: Duration.zero,
        ),
      );

      final result = await coordinator.reconnect();
      expect(result.tokens.accessToken, 'access-3');
      expect(attempts, 3);
      expect(coordinator.state, VtaConnectionState.authenticated);
    });

    test('403 acl errors are not retried endlessly', () async {
      var attempts = 0;
      final service = _FakeAuthService(
        reconnectHandler: ({purpose, scopes = const <String>[]}) async {
          attempts += 1;
          throw const VtaAclException('forbidden', statusCode: 403);
        },
      );

      final coordinator = VtaConnectionCoordinator(
        authService: service,
        sessionManager: service.sessionManager,
        reconnectPolicy: const VtaReconnectPolicy(maxAttempts: 5),
      );

      await expectLater(
        coordinator.reconnect(),
        throwsA(isA<VtaAclException>()),
      );
      expect(attempts, 1);
      expect(coordinator.state, VtaConnectionState.degraded);
    });
  });
}

typedef _BuildRefreshDocument =
    Future<String> Function(VtaRefreshRequest request);
typedef _ParseRefreshResponse =
    Future<VtaAuthenticateResult> Function(String responseBody);
typedef _PostHandler =
    Future<VtaHttpResponse> Function(
      Uri uri,
      Map<String, String> headers,
      Object? body,
    );

typedef _ReconnectHandler =
    Future<VtaAuthenticateResult> Function({
      String? purpose,
      List<String> scopes,
    });

class _FakeProtocol implements VtaAuthProtocol {
  _FakeProtocol({
    this.buildRefreshDocumentHandler,
    this.parseRefreshResponseHandler,
  });

  final _BuildRefreshDocument? buildRefreshDocumentHandler;
  final _ParseRefreshResponse? parseRefreshResponseHandler;

  @override
  Future<String> buildAuthenticateDocument(
    VtaAuthenticateRequest request,
  ) async {
    throw UnimplementedError(
      'buildAuthenticateDocument is not needed in this test',
    );
  }

  @override
  Future<String> buildRefreshDocument(VtaRefreshRequest request) async {
    if (buildRefreshDocumentHandler == null) {
      throw UnimplementedError('buildRefreshDocumentHandler not set');
    }
    return buildRefreshDocumentHandler!(request);
  }

  @override
  Future<String> buildWhoAmIDocument(VtaWhoAmIRequest request) async {
    throw UnimplementedError('buildWhoAmIDocument is not needed in this test');
  }

  @override
  Future<VtaAuthenticateResult> parseAuthenticateResponse(
    String responseBody,
  ) async {
    throw UnimplementedError(
      'parseAuthenticateResponse is not needed in this test',
    );
  }

  @override
  Future<VtaAuthenticateResult> parseRefreshResponse(
    String responseBody,
  ) async {
    if (parseRefreshResponseHandler == null) {
      throw UnimplementedError('parseRefreshResponseHandler not set');
    }
    return parseRefreshResponseHandler!(responseBody);
  }

  @override
  Future<SessionInfo> parseWhoAmIResponse(String responseBody) async {
    throw UnimplementedError('parseWhoAmIResponse is not needed in this test');
  }
}

class _FakeTransport implements VtaHttpTransport {
  _FakeTransport({this.postHandler});

  final _PostHandler? postHandler;

  @override
  Future<VtaHttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    throw StateError('No getHandler was provided for this test.');
  }

  @override
  Future<VtaHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    if (postHandler == null) {
      throw StateError('No postHandler was provided for this test.');
    }
    return postHandler!(uri, headers ?? const {}, body);
  }

  @override
  Future<VtaHttpResponse> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    throw StateError('No putHandler was provided for this test.');
  }
}

class _StaticSigner implements VtaAuthSigner {
  const _StaticSigner();

  @override
  Future<Map<String, dynamic>> createProof({
    required Map<String, dynamic> trustTask,
    required String operation,
  }) async {
    return <String, dynamic>{
      'type': 'DataIntegrityProof',
      'operation': operation,
      'verificationMethod': 'did:key:zHolder#key-1',
      'proofValue': 'zProof',
    };
  }
}

class _FakeAuthService extends VtaAuthService {
  _FakeAuthService({required this.reconnectHandler})
    : super(
        api: _NoopApi(),
        sessionManager: VtaSessionManager(
          client: VtaClient(
            baseUrl: 'https://example.com',
            transport: _FakeTransport(),
          ),
          holderDid: 'did:key:zHolder',
          vtaDid: 'did:webvh:vta.example',
          protocol: _FakeProtocol(),
        ),
        holderDid: 'did:key:zHolder',
        vtaDid: 'did:webvh:vta.example',
        protocol: _FakeProtocol(),
      );

  final _ReconnectHandler reconnectHandler;

  @override
  Future<VtaAuthenticateResult> reconnect({
    String? purpose,
    List<String> scopes = const <String>[],
  }) {
    return reconnectHandler(purpose: purpose, scopes: scopes);
  }
}

class _NoopApi extends VtaAuthApi {
  _NoopApi() : super(transport: const _NoopAuthTransport());
}

class _NoopAuthTransport implements VtaAuthTransport {
  const _NoopAuthTransport();

  Never _fail() {
    throw UnimplementedError('Noop auth transport should not be used directly');
  }

  @override
  Future<Map<String, dynamic>> postChallenge(
    VtaChallengeRequest request,
  ) async {
    _fail();
  }

  @override
  Future<String> postAuthenticate(String trustTaskDocument) async {
    _fail();
  }

  @override
  Future<String> postRefresh(String trustTaskDocument) async {
    _fail();
  }

  @override
  Future<String> postWhoAmI(String trustTaskDocument) async {
    _fail();
  }
}

VtaAuthenticateResult _authResult({
  required String accessToken,
  required DateTime issuedAt,
  String? refreshToken,
  int expiresIn = 900,
  int refreshExpiresIn = 86400,
}) {
  return VtaAuthenticateResult(
    tokens: AuthTokens(
      accessToken: accessToken,
      tokenType: 'Bearer',
      expiresIn: expiresIn,
      refreshToken: refreshToken,
      refreshExpiresIn: refreshToken == null ? null : refreshExpiresIn,
      acr: 'aal1',
      amr: const ['did'],
    ),
    session: SessionInfo(
      sessionId: 'sess-1',
      subject: 'did:key:zHolder',
      issuedAt: issuedAt,
      expiresAt: issuedAt.add(const Duration(minutes: 15)),
      acr: 'aal1',
      amr: const ['did'],
      roles: const <String>[],
      scopes: const <String>[],
    ),
  );
}
