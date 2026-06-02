import 'dart:convert';

import 'package:meeting_place_chat/src/transport/matrix/outgoing/validated_encrypted_file.dart';
import 'package:test/test.dart';

void main() {
  group('ValidatedEncryptedFile', () {
    final validMap = {
      'url': 'mxc://matrix.example.com/media123',
      'key': {
        'kty': 'oct',
        'alg': 'A256CTR',
        'ext': true,
        'k': 'YWJjZA',
        'key_ops': ['encrypt', 'decrypt'],
      },
      'iv': 'MTIzNDU2Nzg5MDEyMzQ1Ng',
      'hashes': {'sha256': 'c2hhMjU2aGFzaA'},
      'v': 'v2',
    };

    final validJson = jsonEncode(validMap);

    test('parses valid encrypted file JSON', () {
      final result = ValidatedEncryptedFile.tryParse(validJson);

      expect(result, isNotNull);
      expect(result!.json['url'], 'mxc://matrix.example.com/media123');
      expect(result.json['iv'], 'MTIzNDU2Nzg5MDEyMzQ1Ng');
      expect(result.json['v'], 'v2');
    });

    test('returns null for null input', () {
      expect(ValidatedEncryptedFile.tryParse(null), isNull);
    });

    test('returns null for empty string', () {
      expect(ValidatedEncryptedFile.tryParse(''), isNull);
    });

    test('returns null for invalid JSON', () {
      expect(ValidatedEncryptedFile.tryParse('{not valid json'), isNull);
    });

    test('returns null for non-map JSON', () {
      expect(ValidatedEncryptedFile.tryParse('"just a string"'), isNull);
    });

    test('rejects missing url', () {
      final json = jsonEncode({
        'key': {'kty': 'oct', 'alg': 'A256CTR', 'k': 'YWJjZA'},
        'iv': 'MTIzNDU2Nzg5MDEyMzQ1Ng',
        'hashes': {'sha256': 'abc'},
        'v': 'v2',
      });
      expect(ValidatedEncryptedFile.tryParse(json), isNull);
    });

    test('rejects non-mxc url', () {
      final json = jsonEncode({
        'url': 'https://not-mxc.com/media',
        'key': {'kty': 'oct', 'alg': 'A256CTR', 'k': 'YWJjZA'},
        'iv': 'MTIzNDU2Nzg5MDEyMzQ1Ng',
        'hashes': {'sha256': 'abc'},
        'v': 'v2',
      });
      expect(ValidatedEncryptedFile.tryParse(json), isNull);
    });

    test('rejects missing key fields', () {
      final json = jsonEncode({
        'url': 'mxc://matrix.example.com/media',
        'key': {'kty': 'oct'},
        'iv': 'MTIzNDU2Nzg5MDEyMzQ1Ng',
        'hashes': {'sha256': 'abc'},
        'v': 'v2',
      });
      expect(ValidatedEncryptedFile.tryParse(json), isNull);
    });

    test('rejects missing iv', () {
      final json = jsonEncode({
        'url': 'mxc://matrix.example.com/media',
        'key': {'kty': 'oct', 'alg': 'A256CTR', 'k': 'YWJjZA'},
        'hashes': {'sha256': 'abc'},
        'v': 'v2',
      });
      expect(ValidatedEncryptedFile.tryParse(json), isNull);
    });

    test('rejects missing sha256 hash', () {
      final json = jsonEncode({
        'url': 'mxc://matrix.example.com/media',
        'key': {'kty': 'oct', 'alg': 'A256CTR', 'k': 'YWJjZA'},
        'iv': 'MTIzNDU2Nzg5MDEyMzQ1Ng',
        'hashes': {'md5': 'abc'},
        'v': 'v2',
      });
      expect(ValidatedEncryptedFile.tryParse(json), isNull);
    });

    test('rejects missing version', () {
      final json = jsonEncode({
        'url': 'mxc://matrix.example.com/media',
        'key': {'kty': 'oct', 'alg': 'A256CTR', 'k': 'YWJjZA'},
        'iv': 'MTIzNDU2Nzg5MDEyMzQ1Ng',
        'hashes': {'sha256': 'abc'},
      });
      expect(ValidatedEncryptedFile.tryParse(json), isNull);
    });

    group('strict value enforcement', () {
      test('rejects version other than v2', () {
        final json = jsonEncode({...validMap, 'v': 'v1'});
        expect(ValidatedEncryptedFile.tryParse(json), isNull);
      });

      test('rejects key.kty other than oct', () {
        final json = jsonEncode({
          ...validMap,
          'key': {...validMap['key'] as Map, 'kty': 'RSA'},
        });
        expect(ValidatedEncryptedFile.tryParse(json), isNull);
      });

      test('rejects key.alg other than A256CTR', () {
        final json = jsonEncode({
          ...validMap,
          'key': {...validMap['key'] as Map, 'alg': 'A128CBC'},
        });
        expect(ValidatedEncryptedFile.tryParse(json), isNull);
      });
    });

    group('URL consistency check', () {
      test('passes when expectedMxcUri matches encrypted url', () {
        final result = ValidatedEncryptedFile.tryParse(
          validJson,
          expectedMxcUri: 'mxc://matrix.example.com/media123',
        );
        expect(result, isNotNull);
      });

      test('rejects when expectedMxcUri does not match encrypted url', () {
        final result = ValidatedEncryptedFile.tryParse(
          validJson,
          expectedMxcUri: 'mxc://matrix.example.com/different',
        );
        expect(result, isNull);
      });

      test('skips URL consistency check when expectedMxcUri is null', () {
        final result = ValidatedEncryptedFile.tryParse(validJson);
        expect(result, isNotNull);
      });
    });
  });
}
