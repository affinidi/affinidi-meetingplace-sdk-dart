import 'dart:convert';

import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';

String encodeCredentialBundle(Map<String, dynamic> payload) {
  return base64Url.encode(utf8.encode(jsonEncode(payload)));
}

VtaAuthenticateResult createStartupSeedAuthResult() {
  final issuedAt = DateTime.utc(2026, 7, 2, 10, 0, 0);
  return VtaAuthenticateResult(
    tokens: const AuthTokens(
      accessToken: 'access-seeded',
      tokenType: 'Bearer',
      expiresIn: 900,
      refreshToken: 'refresh-seeded',
      refreshExpiresIn: 86400,
      acr: 'aal1',
      amr: <String>['did'],
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

class NoopAuthProtocol implements VtaAuthProtocol {
  const NoopAuthProtocol();

  @override
  Future<String> buildAuthenticateDocument(
    VtaAuthenticateRequest request,
  ) async {
    throw UnimplementedError('Not used in this startup example.');
  }

  @override
  Future<String> buildRefreshDocument(VtaRefreshRequest request) async {
    throw UnimplementedError('Not used in this startup example.');
  }

  @override
  Future<String> buildWhoAmIDocument(VtaWhoAmIRequest request) async {
    throw UnimplementedError('Not used in this startup example.');
  }

  @override
  Future<VtaAuthenticateResult> parseAuthenticateResponse(
    String responseBody,
  ) async {
    throw UnimplementedError('Not used in this startup example.');
  }

  @override
  Future<VtaAuthenticateResult> parseRefreshResponse(
    String responseBody,
  ) async {
    throw UnimplementedError('Not used in this startup example.');
  }

  @override
  Future<SessionInfo> parseWhoAmIResponse(String responseBody) async {
    throw UnimplementedError('Not used in this startup example.');
  }
}

class NoopTransport implements VtaHttpTransport {
  @override
  Future<VtaHttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    throw StateError('No network call expected in this example.');
  }

  @override
  Future<VtaHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    throw StateError('No network call expected in this example.');
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
