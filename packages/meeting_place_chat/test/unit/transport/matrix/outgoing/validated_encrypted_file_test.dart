import 'dart:convert';

import 'package:meeting_place_chat/src/transport/matrix/outgoing/validated_encrypted_file.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

void main() {
  group('ValidatedEncryptedFile', () {
    final validMap = {
      encryptedFileFieldUrl: 'mxc://matrix.example.com/media123',
      encryptedFileFieldKey: {
        jsonWebKeyFieldKty: jsonWebKeyType,
        jsonWebKeyFieldAlg: jsonWebKeyAlgorithm,
        jsonWebKeyFieldExt: true,
        jsonWebKeyFieldK: 'YWJjZA',
        jsonWebKeyFieldKeyOps: jsonWebKeyOperations,
      },
      encryptedFileFieldIv: 'MTIzNDU2Nzg5MDEyMzQ1Ng',
      encryptedFileFieldHashes: {encryptedFileSha256Key: 'c2hhMjU2aGFzaA'},
      encryptedFileFieldVersion: encryptedFileInfoVersion,
    };

    final validJson = jsonEncode(validMap);

    test('parses valid encrypted file JSON', () {
      final result = ValidatedEncryptedFile.tryParse(validJson);

      expect(result, isNotNull);
      expect(
        result!.json[encryptedFileFieldUrl],
        'mxc://matrix.example.com/media123',
      );
      expect(result.json[encryptedFileFieldIv], 'MTIzNDU2Nzg5MDEyMzQ1Ng');
      expect(result.json[encryptedFileFieldVersion], encryptedFileInfoVersion);
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
        encryptedFileFieldKey: {
          jsonWebKeyFieldKty: jsonWebKeyType,
          jsonWebKeyFieldAlg: jsonWebKeyAlgorithm,
          jsonWebKeyFieldK: 'YWJjZA',
        },
        encryptedFileFieldIv: 'MTIzNDU2Nzg5MDEyMzQ1Ng',
        encryptedFileFieldHashes: {encryptedFileSha256Key: 'abc'},
        encryptedFileFieldVersion: encryptedFileInfoVersion,
      });
      expect(ValidatedEncryptedFile.tryParse(json), isNull);
    });

    test('rejects non-mxc url', () {
      final json = jsonEncode({
        encryptedFileFieldUrl: 'https://not-mxc.com/media',
        encryptedFileFieldKey: {
          jsonWebKeyFieldKty: jsonWebKeyType,
          jsonWebKeyFieldAlg: jsonWebKeyAlgorithm,
          jsonWebKeyFieldK: 'YWJjZA',
        },
        encryptedFileFieldIv: 'MTIzNDU2Nzg5MDEyMzQ1Ng',
        encryptedFileFieldHashes: {encryptedFileSha256Key: 'abc'},
        encryptedFileFieldVersion: encryptedFileInfoVersion,
      });
      expect(ValidatedEncryptedFile.tryParse(json), isNull);
    });

    test('rejects missing key fields', () {
      final json = jsonEncode({
        encryptedFileFieldUrl: 'mxc://matrix.example.com/media',
        encryptedFileFieldKey: {jsonWebKeyFieldKty: jsonWebKeyType},
        encryptedFileFieldIv: 'MTIzNDU2Nzg5MDEyMzQ1Ng',
        encryptedFileFieldHashes: {encryptedFileSha256Key: 'abc'},
        encryptedFileFieldVersion: encryptedFileInfoVersion,
      });
      expect(ValidatedEncryptedFile.tryParse(json), isNull);
    });

    test('rejects missing iv', () {
      final json = jsonEncode({
        encryptedFileFieldUrl: 'mxc://matrix.example.com/media',
        encryptedFileFieldKey: {
          jsonWebKeyFieldKty: jsonWebKeyType,
          jsonWebKeyFieldAlg: jsonWebKeyAlgorithm,
          jsonWebKeyFieldK: 'YWJjZA',
        },
        encryptedFileFieldHashes: {encryptedFileSha256Key: 'abc'},
        encryptedFileFieldVersion: encryptedFileInfoVersion,
      });
      expect(ValidatedEncryptedFile.tryParse(json), isNull);
    });

    test('rejects missing sha256 hash', () {
      final json = jsonEncode({
        encryptedFileFieldUrl: 'mxc://matrix.example.com/media',
        encryptedFileFieldKey: {
          jsonWebKeyFieldKty: jsonWebKeyType,
          jsonWebKeyFieldAlg: jsonWebKeyAlgorithm,
          jsonWebKeyFieldK: 'YWJjZA',
        },
        encryptedFileFieldIv: 'MTIzNDU2Nzg5MDEyMzQ1Ng',
        encryptedFileFieldHashes: {'md5': 'abc'},
        encryptedFileFieldVersion: encryptedFileInfoVersion,
      });
      expect(ValidatedEncryptedFile.tryParse(json), isNull);
    });

    test('rejects missing version', () {
      final json = jsonEncode({
        encryptedFileFieldUrl: 'mxc://matrix.example.com/media',
        encryptedFileFieldKey: {
          jsonWebKeyFieldKty: jsonWebKeyType,
          jsonWebKeyFieldAlg: jsonWebKeyAlgorithm,
          jsonWebKeyFieldK: 'YWJjZA',
        },
        encryptedFileFieldIv: 'MTIzNDU2Nzg5MDEyMzQ1Ng',
        encryptedFileFieldHashes: {encryptedFileSha256Key: 'abc'},
      });
      expect(ValidatedEncryptedFile.tryParse(json), isNull);
    });

    group('strict value enforcement', () {
      test('rejects version other than v2', () {
        final json = jsonEncode({...validMap, encryptedFileFieldVersion: 'v1'});
        expect(ValidatedEncryptedFile.tryParse(json), isNull);
      });

      test('rejects key.kty other than oct', () {
        final json = jsonEncode({
          ...validMap,
          encryptedFileFieldKey: {
            ...validMap[encryptedFileFieldKey] as Map,
            jsonWebKeyFieldKty: 'RSA',
          },
        });
        expect(ValidatedEncryptedFile.tryParse(json), isNull);
      });

      test('rejects key.alg other than A256CTR', () {
        final json = jsonEncode({
          ...validMap,
          encryptedFileFieldKey: {
            ...validMap[encryptedFileFieldKey] as Map,
            jsonWebKeyFieldAlg: 'A128CBC',
          },
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
