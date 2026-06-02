import 'dart:convert';
import 'dart:typed_data';

const encryptedFileInfoVersion = 'v2';
const encryptedFileSha256Key = 'sha256';
const jsonWebKeyType = 'oct';
const jsonWebKeyAlgorithm = 'A256CTR';
const jsonWebKeyOperations = ['encrypt', 'decrypt'];

/// Represents the encryption metadata for a file uploaded to a media
/// repository.
///
/// Follows the Matrix encrypted attachment format (AES-CTR-256).
/// The decryption key and IV travel inside the DIDComm-encrypted message,
/// so only the intended recipient can access them.
class EncryptedFileInfo {
  EncryptedFileInfo({
    required this.url,
    required this.key,
    required this.iv,
    required this.hashes,
    this.version = encryptedFileInfoVersion,
  });

  factory EncryptedFileInfo.fromJson(Map<String, dynamic> json) {
    if (json case {
      'url': final String url,
      'key': final Map<String, dynamic> keyJson,
      'iv': final String iv,
      'hashes': final Map<String, dynamic> hashesRaw,
      'v': final String version,
    }) {
      if (version != encryptedFileInfoVersion) {
        throw const FormatException(
          'Invalid EncryptedFileInfo JSON: bad version',
        );
      }
      return EncryptedFileInfo(
        url: url,
        key: JsonWebKey.fromJson(keyJson),
        iv: iv,
        hashes: _parseStringMap(hashesRaw),
        version: version,
      );
    }
    throw const FormatException(
      'Invalid EncryptedFileInfo JSON: missing required fields',
    );
  }

  /// The mxc:// URI of the encrypted file on the media repository.
  final String url;

  /// The AES-CTR-256 key in JWK format.
  final JsonWebKey key;

  /// The 128-bit initialization vector (base64url-unpadded).
  /// Format: 64-bit random prefix + 64-bit zero counter.
  final String iv;

  /// Hash of the ciphertext. Key is algorithm name (e.g. 'sha256'),
  /// value is base64url-unpadded hash.
  final Map<String, String> hashes;

  /// Encryption format version. Must be 'v2'.
  final String version;

  Map<String, dynamic> toJson() => {
    'url': url,
    'key': key.toJson(),
    'iv': iv,
    'hashes': hashes,
    'v': version,
  };
}

/// A JSON Web Key for AES-CTR-256 symmetric encryption.
class JsonWebKey {
  JsonWebKey({
    required this.k,
    this.kty = jsonWebKeyType,
    this.alg = jsonWebKeyAlgorithm,
    this.ext = true,
    this.keyOps = jsonWebKeyOperations,
  });

  factory JsonWebKey.fromJson(Map<String, dynamic> json) {
    if (json case {
      'kty': final String kty,
      'alg': final String alg,
      'k': final String k,
    }) {
      if (kty != jsonWebKeyType || alg != jsonWebKeyAlgorithm) {
        throw const FormatException(
          'Invalid JsonWebKey JSON: bad key metadata',
        );
      }
      return JsonWebKey(
        kty: kty,
        alg: alg,
        ext: json['ext'] is bool ? json['ext'] as bool : true,
        k: k,
        keyOps: _parseStringList(json['key_ops']) ?? jsonWebKeyOperations,
      );
    }
    throw const FormatException(
      'Invalid JsonWebKey JSON: missing required fields '
      '(kty, alg, k)',
    );
  }

  /// Key type. Always 'oct' for symmetric keys.
  final String kty;

  /// Algorithm. Always 'A256CTR' for AES-CTR-256.
  final String alg;

  /// Whether the key is extractable (W3C WebCrypto extension).
  final bool ext;

  /// The raw key bytes encoded as base64url (unpadded).
  final String k;

  /// Permitted key operations.
  final List<String> keyOps;

  /// Returns the raw key bytes.
  Uint8List get keyBytes => base64Url.decode(_padBase64(k));

  Map<String, dynamic> toJson() => {
    'kty': kty,
    'alg': alg,
    'ext': ext,
    'k': k,
    'key_ops': keyOps,
  };
}

String _padBase64(String input) {
  final remainder = input.length % 4;
  if (remainder == 0) return input;
  return input + '=' * (4 - remainder);
}

Map<String, String> _parseStringMap(Map<String, dynamic> raw) {
  final result = <String, String>{};
  for (final entry in raw.entries) {
    if (entry.value is! String) {
      throw const FormatException('Invalid EncryptedFileInfo JSON: bad hash');
    }
    result[entry.key] = entry.value as String;
  }
  if (!result.containsKey(encryptedFileSha256Key)) {
    throw const FormatException(
      'Invalid EncryptedFileInfo JSON: missing sha256',
    );
  }
  return result;
}

List<String>? _parseStringList(Object? raw) {
  if (raw == null) return null;
  if (raw is! List) {
    throw const FormatException('Invalid JsonWebKey JSON: bad key_ops');
  }
  final result = <String>[];
  for (final value in raw) {
    if (value is! String) {
      throw const FormatException('Invalid JsonWebKey JSON: bad key_ops');
    }
    result.add(value);
  }
  return result;
}
