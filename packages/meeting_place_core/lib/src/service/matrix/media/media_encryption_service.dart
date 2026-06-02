import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

import 'encrypted_file_info.dart';

/// Result of encrypting a file for upload.
class EncryptionResult {
  EncryptionResult({
    required this.ciphertext,
    required this.key,
    required this.iv,
    required this.sha256Hash,
  });

  /// The encrypted file bytes.
  final Uint8List ciphertext;

  /// The AES-CTR-256 key in JWK format.
  final JsonWebKey key;

  /// The 128-bit IV as base64url-unpadded string.
  final String iv;

  /// SHA-256 hash of the ciphertext as base64url-unpadded string.
  final String sha256Hash;

  /// Builds an [EncryptedFileInfo] after the ciphertext has been uploaded.
  EncryptedFileInfo toEncryptedFileInfo(String mxcUrl) => EncryptedFileInfo(
    url: mxcUrl,
    key: key,
    iv: iv,
    hashes: {encryptedFileSha256Key: sha256Hash},
  );
}

/// Handles client-side AES-CTR-256 encryption and decryption of media files.
///
/// Follows the Matrix encrypted attachment specification:
/// - AES-CTR with 256-bit key
/// - 128-bit IV: 64-bit random prefix + 64-bit zero counter
/// - SHA-256 hash of ciphertext for integrity verification
class MediaEncryptionService {
  MediaEncryptionService({Random? secureRandom})
    : _random = secureRandom ?? Random.secure();

  final Random _random;

  /// Encrypts [plaintext] using AES-CTR-256.
  ///
  /// Generates a fresh random key and IV for each call.
  /// Returns the ciphertext along with the key, IV, and hash needed for
  /// decryption.
  EncryptionResult encrypt(Uint8List plaintext) {
    final keyBytes = _generateRandomBytes(32);
    final ivBytes = Uint8List(16);
    final randomPrefix = _generateRandomBytes(8);
    ivBytes.setRange(0, 8, randomPrefix);

    final ciphertext = _aesCtrProcess(plaintext, keyBytes, ivBytes);
    final hash = sha256.convert(ciphertext);

    return EncryptionResult(
      ciphertext: ciphertext,
      key: JsonWebKey(k: _toBase64UrlUnpadded(keyBytes)),
      iv: _toBase64UrlUnpadded(ivBytes),
      sha256Hash: _toBase64UrlUnpadded(Uint8List.fromList(hash.bytes)),
    );
  }

  /// Decrypts [ciphertext] using the key and IV from [fileInfo].
  ///
  /// Verifies the SHA-256 hash of the ciphertext before decrypting.
  /// Throws [MediaDecryptionException] if the hash does not match.
  Uint8List decrypt(Uint8List ciphertext, EncryptedFileInfo fileInfo) {
    final expectedHash = fileInfo.hashes[encryptedFileSha256Key];
    if (expectedHash == null) {
      throw MediaDecryptionException('Missing sha256 hash for encrypted media');
    }
    final actualHash = sha256.convert(ciphertext);
    final actualHashStr = _toBase64UrlUnpadded(
      Uint8List.fromList(actualHash.bytes),
    );
    if (actualHashStr != expectedHash) {
      throw MediaDecryptionException(
        'Ciphertext hash mismatch: expected $expectedHash, '
        'got $actualHashStr',
      );
    }

    final keyBytes = fileInfo.key.keyBytes;
    final ivBytes = base64Url.decode(_padBase64(fileInfo.iv));

    return _aesCtrProcess(ciphertext, keyBytes, ivBytes);
  }

  Uint8List _aesCtrProcess(
    Uint8List input,
    Uint8List keyBytes,
    Uint8List ivBytes,
  ) {
    final params = ParametersWithIV<KeyParameter>(
      KeyParameter(keyBytes),
      ivBytes,
    );
    final cipher = StreamCipher('AES/CTR');
    cipher.init(true, params);
    return cipher.process(input);
  }

  Uint8List _generateRandomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }
}

String _toBase64UrlUnpadded(Uint8List bytes) {
  return base64Url.encode(bytes).replaceAll('=', '');
}

String _padBase64(String input) {
  final remainder = input.length % 4;
  if (remainder == 0) return input;
  return input + '=' * (4 - remainder);
}

/// Exception thrown when media decryption fails.
class MediaDecryptionException implements Exception {
  MediaDecryptionException(this.message);

  final String message;

  @override
  String toString() => 'MediaDecryptionException: $message';
}
