import 'dart:convert';

import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';

VtaHttpTransport createAuthWorkflowMockTransport() {
  return _StubTransport(
    postHandler: (uri, headers, body) async {
      if (uri.path == '/auth/challenge') {
        return VtaHttpResponse(
          statusCode: 200,
          body:
              '{"challenge":"nonce-1","sessionId":"sess-1","expiresAt":"2026-07-01T00:01:00Z"}',
        );
      }

      if (uri.path == '/auth/') {
        return VtaHttpResponse(statusCode: 200, body: '{"tt":"auth"}');
      }

      if (uri.path == '/api/trust-tasks') {
        final doc = jsonDecode(body as String) as Map<String, dynamic>;
        final type = doc['type'] as String?;

        if (type == 'whoami') {
          return VtaHttpResponse(
            statusCode: 200,
            body: jsonEncode(<String, dynamic>{
              'payload': <String, dynamic>{
                'session': <String, dynamic>{
                  'session_id': 'sess-1',
                  'subject': 'did:key:zHolder',
                  'issued_at': '2026-07-01T00:00:00Z',
                  'expires_at': '2026-07-01T00:15:00Z',
                  'acr': 'aal1',
                  'amr': <String>['did'],
                },
                'roles': <String>['application'],
                'scopes': <String>['auth:read'],
              },
            }),
          );
        }

        if (type == 'refresh') {
          return VtaHttpResponse(statusCode: 200, body: '{"tt":"refresh"}');
        }
      }

      throw StateError('Unexpected request path: ${uri.path}');
    },
  );
}

VtaAuthProtocol createAuthWorkflowMockProtocol() {
  return _StubAuthProtocol();
}

typedef _PostHandler =
    Future<VtaHttpResponse> Function(
      Uri uri,
      Map<String, String> headers,
      Object? body,
    );

class _StubTransport implements VtaHttpTransport {
  _StubTransport({required this.postHandler});

  final _PostHandler postHandler;

  @override
  Future<VtaHttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    throw StateError('GET is not used by this example.');
  }

  @override
  Future<VtaHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return postHandler(uri, headers ?? const <String, String>{}, body);
  }

  @override
  Future<VtaHttpResponse> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    // TODO: implement put
    throw UnimplementedError();
  }
}

class _StubAuthProtocol implements VtaAuthProtocol {
  @override
  Future<String> buildAuthenticateDocument(
    VtaAuthenticateRequest request,
  ) async {
    return jsonEncode(<String, dynamic>{
      'type': 'authenticate',
      'holder_did': request.holderDid,
      'vta_did': request.vtaDid,
      'challenge': request.challenge,
      'session_id': request.sessionId,
      'scopes': request.scopes,
    });
  }

  @override
  Future<String> buildRefreshDocument(VtaRefreshRequest request) async {
    return jsonEncode(<String, dynamic>{
      'type': 'refresh',
      'holder_did': request.holderDid,
      'vta_did': request.vtaDid,
      'refresh_token': request.refreshToken,
      'scopes': request.scopes,
    });
  }

  @override
  Future<String> buildWhoAmIDocument(VtaWhoAmIRequest request) async {
    return jsonEncode(<String, dynamic>{
      'type': 'whoami',
      'holder_did': request.holderDid,
      'vta_did': request.vtaDid,
    });
  }

  @override
  Future<VtaAuthenticateResult> parseAuthenticateResponse(
    String responseBody,
  ) async {
    return _seedAuthResult(token: 'access-1', refreshToken: 'refresh-1');
  }

  @override
  Future<VtaAuthenticateResult> parseRefreshResponse(
    String responseBody,
  ) async {
    return _seedAuthResult(token: 'access-2', refreshToken: 'refresh-2');
  }

  @override
  Future<SessionInfo> parseWhoAmIResponse(String responseBody) async {
    final root = jsonDecode(responseBody) as Map<String, dynamic>;
    final payload = root['payload'] as Map<String, dynamic>;
    return SessionInfo.fromJson(<String, dynamic>{
      ...(payload['session'] as Map<String, dynamic>),
      'roles': payload['roles'],
      'scopes': payload['scopes'],
    });
  }
}

VtaAuthenticateResult _seedAuthResult({
  required String token,
  required String refreshToken,
}) {
  final issuedAt = DateTime.now().toUtc();
  return VtaAuthenticateResult(
    tokens: AuthTokens(
      accessToken: token,
      tokenType: 'Bearer',
      expiresIn: 900,
      refreshToken: refreshToken,
      refreshExpiresIn: 86400,
      acr: 'aal1',
      amr: const <String>['did'],
    ),
    session: SessionInfo(
      sessionId: 'sess-1',
      subject: 'did:key:zHolder',
      issuedAt: issuedAt,
      expiresAt: issuedAt.add(const Duration(minutes: 15)),
      acr: 'aal1',
      amr: const <String>['did'],
      roles: const <String>[],
      scopes: const <String>[],
    ),
  );
}
