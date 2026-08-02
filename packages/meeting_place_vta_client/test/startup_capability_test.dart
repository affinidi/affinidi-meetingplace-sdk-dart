import 'dart:convert';

import 'package:test/test.dart';
import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';

void main() {
  group('VtaStartupCapability', () {
    test('initializes from credential bundle and restores snapshot', () async {
      final store = VtaInMemorySecureStore();
      final capability = VtaStartupCapability(
        secureStore: store,
        clock: () => DateTime.utc(2026, 7, 2, 10),
      );

      final encodedBundle = _encodeBundle({
        'did': 'did:key:zHolder',
        'vta_url': 'https://vta.example',
        'private_key_multibase': 'z3u2secret',
        'context_id': 'ctx-personal',
        'key_id': 'holder-ed25519-1',
      });

      final snapshot = await capability.initializeFromCredentialBundle(
        encodedCredentialBundle: encodedBundle,
        config: const VtaConfig(
          baseUrl: 'https://vta.example',
          vtaDid: 'did:webvh:vta.example',
          mediatorDid: 'did:web:mediator.example',
        ),
      );

      expect(snapshot.holderDid, 'did:key:zHolder');
      expect(snapshot.contextId, 'ctx-personal');
      expect(snapshot.authResult, isNull);

      final restored = await capability.restore();
      expect(restored, isNotNull);
      expect(restored!.config.vtaDid, 'did:webvh:vta.example');
      expect(restored.credential.keyId, 'holder-ed25519-1');
    });

    test('fails when config baseUrl and bundle vta_url mismatch', () async {
      final store = VtaInMemorySecureStore();
      final capability = VtaStartupCapability(secureStore: store);

      final encodedBundle = _encodeBundle({
        'did': 'did:key:zHolder',
        'vta_url': 'https://vta-other.example',
        'private_key_multibase': 'z3u2secret',
      });

      await expectLater(
        capability.initializeFromCredentialBundle(
          encodedCredentialBundle: encodedBundle,
          config: const VtaConfig(
            baseUrl: 'https://vta.example',
            vtaDid: 'did:webvh:vta.example',
          ),
        ),
        throwsA(
          isA<VtaValidationException>().having(
            (error) => error.code,
            'code',
            'e.vta.startup.vta_url_mismatch',
          ),
        ),
      );
    });

    test('persists auth result and hydrates session manager', () async {
      final now = DateTime.utc(2026, 7, 2, 10);
      final store = VtaInMemorySecureStore();
      final capability = VtaStartupCapability(
        secureStore: store,
        clock: () => now,
      );

      final encodedBundle = _encodeBundle({
        'did': 'did:key:zHolder',
        'vta_url': 'https://vta.example',
        'private_key_multibase': 'z3u2secret',
      });

      final startupSnapshot = await capability.initializeFromCredentialBundle(
        encodedCredentialBundle: encodedBundle,
        config: const VtaConfig(
          baseUrl: 'https://vta.example',
          vtaDid: 'did:webvh:vta.example',
        ),
      );

      final authResult = _authResult(issuedAt: now, token: 'access-1');
      await capability.persistAuthResult(
        snapshot: startupSnapshot,
        authResult: authResult,
      );

      final restored = await capability.restore();
      expect(restored, isNotNull);
      expect(restored!.authResult, isNotNull);

      final client = VtaClient(
        baseUrl: 'https://vta.example',
        transport: _NoopTransport(),
      );
      final sessionManager = VtaSessionManager(
        client: client,
        holderDid: 'did:key:zHolder',
        vtaDid: 'did:webvh:vta.example',
        protocol: const _NoopAuthProtocol(),
      );

      capability.hydrateSessionManager(
        sessionManager: sessionManager,
        snapshot: restored,
      );

      expect(sessionManager.tokens?.accessToken, 'access-1');
      expect(client.authToken, 'access-1');
    });

    test('maps storage read failures to cache exception', () async {
      final capability = VtaStartupCapability(secureStore: _ThrowingStore());

      await expectLater(
        capability.restore(),
        throwsA(
          isA<VtaCacheException>().having(
            (error) => error.code,
            'code',
            'e.vta.startup.cache_read_failed',
          ),
        ),
      );
    });

    test('restoreAuthRuntime builds hydrated workflow/coordinator', () async {
      final now = DateTime.utc(2026, 7, 2, 10);
      final store = VtaInMemorySecureStore();
      final capability = VtaStartupCapability(
        secureStore: store,
        clock: () => now,
      );

      final encodedBundle = _encodeBundle({
        'did': 'did:key:zHolder',
        'vta_url': 'https://vta.example',
        'private_key_multibase': 'z3u2secret',
      });

      final startupSnapshot = await capability.initializeFromCredentialBundle(
        encodedCredentialBundle: encodedBundle,
        config: const VtaConfig(
          baseUrl: 'https://vta.example',
          vtaDid: 'did:webvh:vta.example',
        ),
      );

      final authResult = _authResult(issuedAt: now, token: 'access-runtime');
      await capability.persistAuthResult(
        snapshot: startupSnapshot,
        authResult: authResult,
      );

      final runtime = await capability.restoreAuthRuntime(
        protocol: const _NoopAuthProtocol(),
        transport: _NoopTransport(),
      );

      expect(runtime, isNotNull);
      expect(runtime!.snapshot.holderDid, 'did:key:zHolder');
      expect(runtime.sessionManager.tokens?.accessToken, 'access-runtime');
      expect(runtime.client.authToken, 'access-runtime');
      expect(
        runtime.connectionCoordinator.state,
        VtaConnectionState.disconnected,
      );
    });
  });
}

String _encodeBundle(Map<String, dynamic> payload) {
  return base64Url.encode(utf8.encode(jsonEncode(payload)));
}

VtaAuthenticateResult _authResult({
  required DateTime issuedAt,
  required String token,
}) {
  return VtaAuthenticateResult(
    tokens: AuthTokens(
      accessToken: token,
      tokenType: 'Bearer',
      expiresIn: 900,
      refreshToken: 'refresh-1',
      refreshExpiresIn: 86400,
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

class _NoopTransport implements VtaHttpTransport {
  @override
  Future<VtaHttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    throw StateError('Not used in this test.');
  }

  @override
  Future<VtaHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    throw StateError('Not used in this test.');
  }

  @override
  Future<VtaHttpResponse> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    throw StateError('Not used in this test.');
  }
}

class _ThrowingStore implements VtaSecureStore {
  @override
  Future<void> delete({required String key}) async {
    throw StateError('delete failure');
  }

  @override
  Future<String?> read({required String key}) async {
    throw StateError('read failure');
  }

  @override
  Future<void> write({required String key, required String value}) async {
    throw StateError('write failure');
  }
}

class _NoopAuthProtocol implements VtaAuthProtocol {
  const _NoopAuthProtocol();

  @override
  Future<String> buildAuthenticateDocument(
    VtaAuthenticateRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<String> buildRefreshDocument(VtaRefreshRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<String> buildWhoAmIDocument(VtaWhoAmIRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<VtaAuthenticateResult> parseAuthenticateResponse(
    String responseBody,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<VtaAuthenticateResult> parseRefreshResponse(
    String responseBody,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<SessionInfo> parseWhoAmIResponse(String responseBody) async {
    throw UnimplementedError();
  }
}
