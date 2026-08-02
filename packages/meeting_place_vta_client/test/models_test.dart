import 'package:json_annotation/json_annotation.dart';
import 'package:test/test.dart';
import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';

Matcher get _modelDecodeFailure => throwsA(
  anyOf(
    isA<CheckedFromJsonException>(),
    isA<MissingRequiredKeysException>(),
    isA<TypeError>(),
    isA<FormatException>(),
  ),
);

void main() {
  group('VtaConfig', () {
    test('parses valid JSON and serializes back', () {
      final model = VtaConfig.fromJson({
        'base_url': 'http://127.0.0.1:8100',
        'vta_did': 'did:webvh:example',
        'mediator_did': 'did:key:zMediator',
      });

      expect(model.baseUrl, 'http://127.0.0.1:8100');
      expect(model.vtaDid, 'did:webvh:example');
      expect(model.mediatorDid, 'did:key:zMediator');
      expect(model.toJson()['base_url'], 'http://127.0.0.1:8100');
    });

    test('throws parse exception when required fields are missing', () {
      expect(
        () => VtaConfig.fromJson({'vta_did': 'did:key:z123'}),
        _modelDecodeFailure,
      );
    });
  });

  group('AuthTokens', () {
    test('parses valid auth token response', () {
      final tokens = AuthTokens.fromJson({
        'access_token': 'access',
        'token_type': 'Bearer',
        'expires_in': 900,
        'refresh_token': 'refresh',
        'refresh_expires_in': 86400,
        'acr': 'aal2',
        'amr': ['did-signed'],
      });

      expect(tokens.accessToken, 'access');
      expect(tokens.expiresIn, 900);
      expect(tokens.amr, ['did-signed']);
      expect(tokens.toJson()['token_type'], 'Bearer');
    });

    test('throws parse exception on malformed payload', () {
      expect(
        () => AuthTokens.fromJson({'token_type': 'Bearer', 'expires_in': 900}),
        _modelDecodeFailure,
      );
    });
  });

  group('SessionInfo', () {
    test('parses and serializes session payload', () {
      final session = SessionInfo.fromJson({
        'session_id': 'session-1',
        'subject': 'did:key:zHolder',
        'issued_at': '2026-06-30T00:00:00Z',
        'expires_at': '2026-06-30T00:15:00Z',
        'roles': ['application'],
        'scopes': ['auth:read'],
      });

      expect(session.sessionId, 'session-1');
      expect(session.roles, ['application']);
      expect(session.toJson()['subject'], 'did:key:zHolder');
    });

    test('throws parse exception for invalid list values', () {
      expect(
        () => SessionInfo.fromJson({
          'session_id': 'session-1',
          'subject': 'did:key:zHolder',
          'issued_at': '2026-06-30T00:00:00Z',
          'expires_at': '2026-06-30T00:15:00Z',
          'roles': [1],
        }),
        _modelDecodeFailure,
      );
    });
  });

  group('DidSecretsBundle', () {
    test('parses bundle and secrets list', () {
      final bundle = DidSecretsBundle.fromJson({
        'did': 'did:key:zHolder',
        'secrets': [
          {
            'key_id': 'holder-ed25519-1',
            'key_type': 'Ed25519',
            'private_key_multibase': 'z3u2...',
          },
        ],
      });

      expect(bundle.did, 'did:key:zHolder');
      expect(bundle.secrets.length, 1);
      expect(bundle.toJson()['did'], 'did:key:zHolder');
    });

    test('throws parse exception when secrets missing', () {
      expect(
        () => DidSecretsBundle.fromJson({'did': 'did:key:zHolder'}),
        _modelDecodeFailure,
      );
    });
  });

  group('Key/sign models', () {
    test('parses VtaKeyRecord and SignResponse', () {
      final key = VtaKeyRecord.fromJson({
        'key_id': 'key-1',
        'key_type': 'Ed25519',
        'status': 'active',
      });
      final sign = SignResponse.fromJson({
        'signature': 'MEUCIQ...',
        'algorithm': 'EdDSA',
        'key_id': 'key-1',
      });

      expect(key.keyType, 'Ed25519');
      expect(sign.signature, 'MEUCIQ...');
    });

    test('throws parse exception when required sign field missing', () {
      expect(
        () => SignResponse.fromJson({'algorithm': 'EdDSA'}),
        _modelDecodeFailure,
      );
    });
  });
}
