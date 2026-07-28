import 'dart:convert';

import 'package:test/test.dart';
import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';

void main() {
  group('VtaCredentialBundle.parse', () {
    test('parses valid base64url JSON payload', () {
      final payload = {
        'did': 'did:key:zHolder',
        'vta_url': 'http://127.0.0.1:8100',
        'private_key_multibase': 'z3u2secret',
        'context_id': 'mpx-local',
        'key_id': 'holder-ed25519-1',
      };
      final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));

      final parsed = VtaCredentialBundle.parse(encoded);

      expect(parsed.did, 'did:key:zHolder');
      expect(parsed.vtaUrl, 'http://127.0.0.1:8100');
      expect(parsed.contextId, 'mpx-local');
      expect(parsed.toJson()['private_key_multibase'], 'z3u2secret');
    });

    test('supports alias keys for URL and private key', () {
      final payload = {
        'holder_did': 'did:key:zHolder',
        'url': 'http://127.0.0.1:8100',
        'privateKeyMultibase': 'z3u2secret',
      };
      final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));

      final parsed = VtaCredentialBundle.parse(encoded);

      expect(parsed.did, 'did:key:zHolder');
      expect(parsed.vtaUrl, 'http://127.0.0.1:8100');
      expect(parsed.privateKeyMultibase, 'z3u2secret');
    });

    test('throws validation exception for empty input', () {
      expect(
        () => VtaCredentialBundle.parse('  '),
        throwsA(isA<VtaValidationException>()),
      );
    });

    test('throws parse exception for invalid base64url', () {
      expect(
        () => VtaCredentialBundle.parse('@@@not-valid@@@'),
        throwsA(isA<VtaParseException>()),
      );
    });

    test('throws parse exception for decoded non-JSON content', () {
      final encoded = base64Url.encode(utf8.encode('not-json'));
      expect(
        () => VtaCredentialBundle.parse(encoded),
        throwsA(isA<VtaParseException>()),
      );
    });

    test('throws parse exception when required fields missing', () {
      final encoded = base64Url.encode(
        utf8.encode(jsonEncode({'did': 'did:key:zHolder'})),
      );
      expect(
        () => VtaCredentialBundle.parse(encoded),
        throwsA(isA<VtaParseException>()),
      );
    });
  });

  group('VtaException hierarchy', () {
    test('returns type-tagged exception string', () {
      const error = VtaAclException(
        'Forbidden',
        statusCode: 403,
        code: 'e.vta.auth.forbidden',
      );
      final asString = error.toString();
      expect(asString.contains('type=acl'), isTrue);
      expect(asString.contains('statusCode=403'), isTrue);
    });
  });
}
