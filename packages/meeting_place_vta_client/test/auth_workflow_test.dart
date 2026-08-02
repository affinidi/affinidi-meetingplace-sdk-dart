import 'dart:convert';

import 'package:test/test.dart';
import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';

void main() {
  group('VtaAuthWorkflow', () {
    test('connect runs challenge then authenticate and stores session', () async {
      final transport = _FakeTransport(
        postHandler: (uri, headers, body) async {
          if (uri.path == '/auth/challenge') {
            return VtaHttpResponse(
              statusCode: 200,
              body:
                  '{"challenge":"nonce-1","sessionId":"sess-1","expiresAt":"2026-07-01T00:01:00Z"}',
            );
          }

          if (uri.path == '/auth/') {
            expect(body, '{"doc":"authenticate"}');
            return VtaHttpResponse(statusCode: 200, body: '{"tt":"auth"}');
          }

          throw StateError('Unexpected path ${uri.path}');
        },
      );

      final client = VtaClient(
        baseUrl: 'https://example.com',
        transport: transport,
      );
      final workflow = VtaAuthWorkflow(
        client: client,
        holderDid: 'did:key:zHolder',
        vtaDid: 'did:webvh:vta.example',
        protocol: _FakeProtocol(
          buildAuthenticateDocumentHandler: (_) async =>
              '{"doc":"authenticate"}',
          parseAuthenticateResponseHandler: (_) async => _authResult(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
            issuedAt: DateTime.utc(2026, 7, 1),
          ),
        ),
      );

      final result = await workflow.connect();
      expect(result.tokens.accessToken, 'access-1');
      expect(workflow.sessionManager.tokens?.accessToken, 'access-1');
      expect(client.authToken, 'access-1');
    });

    test('whoAmI ensures token validity then parses response', () async {
      final now = DateTime.utc(2026, 7, 1, 12);
      final transport = _FakeTransport(
        postHandler: (uri, headers, body) async {
          if (uri.path == '/api/trust-tasks') {
            expect(body, '{"doc":"whoami"}');
            return VtaHttpResponse(
              statusCode: 200,
              body: jsonEncode({
                'payload': {
                  'session': {
                    'session_id': 'sess-1',
                    'subject': 'did:key:zHolder',
                    'issued_at': '2026-07-01T12:00:00Z',
                    'expires_at': '2026-07-01T12:15:00Z',
                    'acr': 'aal2',
                    'amr': ['did'],
                  },
                  'roles': ['application'],
                  'scopes': ['auth:read'],
                },
              }),
            );
          }

          throw StateError('Unexpected path ${uri.path}');
        },
      );

      final protocol = _FakeProtocol(
        buildWhoAmIDocumentHandler: (_) async => '{"doc":"whoami"}',
        parseWhoAmIResponseHandler: (body) async {
          final root = jsonDecode(body) as Map<String, dynamic>;
          final payload = root['payload'] as Map<String, dynamic>;
          return SessionInfo.fromJson({
            ...(payload['session'] as Map<String, dynamic>),
            'roles': payload['roles'],
            'scopes': payload['scopes'],
          });
        },
      );

      final client = VtaClient(
        baseUrl: 'https://example.com',
        transport: transport,
      );
      final manager =
          VtaSessionManager(
            client: client,
            holderDid: 'did:key:zHolder',
            vtaDid: 'did:webvh:vta.example',
            protocol: protocol,
            clock: () => now,
          )..applyAuthenticateResult(
            _authResult(
              accessToken: 'access-1',
              refreshToken: 'refresh-1',
              issuedAt: now,
            ),
          );

      final workflow = VtaAuthWorkflow(
        client: client,
        holderDid: 'did:key:zHolder',
        vtaDid: 'did:webvh:vta.example',
        protocol: protocol,
        sessionManager: manager,
      );

      final whoami = await workflow.whoAmI();
      expect(whoami.sessionId, 'sess-1');
      expect(whoami.roles, ['application']);
    });
  });
}

typedef _BuildAuthenticateDocument =
    Future<String> Function(VtaAuthenticateRequest request);
typedef _ParseAuthenticateResponse =
    Future<VtaAuthenticateResult> Function(String responseBody);
typedef _BuildWhoAmIDocument =
    Future<String> Function(VtaWhoAmIRequest request);
typedef _ParseWhoAmIResponse =
    Future<SessionInfo> Function(String responseBody);
typedef _PostHandler =
    Future<VtaHttpResponse> Function(
      Uri uri,
      Map<String, String> headers,
      Object? body,
    );

class _FakeProtocol implements VtaAuthProtocol {
  _FakeProtocol({
    this.buildAuthenticateDocumentHandler,
    this.parseAuthenticateResponseHandler,
    this.buildWhoAmIDocumentHandler,
    this.parseWhoAmIResponseHandler,
  });

  final _BuildAuthenticateDocument? buildAuthenticateDocumentHandler;
  final _ParseAuthenticateResponse? parseAuthenticateResponseHandler;
  final _BuildWhoAmIDocument? buildWhoAmIDocumentHandler;
  final _ParseWhoAmIResponse? parseWhoAmIResponseHandler;

  @override
  Future<String> buildAuthenticateDocument(
    VtaAuthenticateRequest request,
  ) async {
    if (buildAuthenticateDocumentHandler == null) {
      throw UnimplementedError('buildAuthenticateDocumentHandler not set');
    }
    return buildAuthenticateDocumentHandler!(request);
  }

  @override
  Future<String> buildRefreshDocument(VtaRefreshRequest request) async {
    return '{}';
  }

  @override
  Future<String> buildWhoAmIDocument(VtaWhoAmIRequest request) async {
    if (buildWhoAmIDocumentHandler == null) {
      throw UnimplementedError('buildWhoAmIDocumentHandler not set');
    }
    return buildWhoAmIDocumentHandler!(request);
  }

  @override
  Future<VtaAuthenticateResult> parseAuthenticateResponse(
    String responseBody,
  ) async {
    if (parseAuthenticateResponseHandler == null) {
      throw UnimplementedError('parseAuthenticateResponseHandler not set');
    }
    return parseAuthenticateResponseHandler!(responseBody);
  }

  @override
  Future<VtaAuthenticateResult> parseRefreshResponse(
    String responseBody,
  ) async {
    throw UnimplementedError('parseRefreshResponse is not needed in this test');
  }

  @override
  Future<SessionInfo> parseWhoAmIResponse(String responseBody) async {
    if (parseWhoAmIResponseHandler == null) {
      throw UnimplementedError('parseWhoAmIResponseHandler not set');
    }
    return parseWhoAmIResponseHandler!(responseBody);
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
