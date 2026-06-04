import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

/// Validated Matrix encrypted-file metadata for an `m.room.message` event.
///
/// This is a transport-layer type that ensures the JSON carried on a
/// `ChatAttachment` actually conforms to the Matrix encrypted attachment
/// structure before it is forwarded to the homeserver as the `file` field.
///
/// Required fields (per Matrix Client-Server spec):
/// - `url`: `mxc://` URI of the encrypted ciphertext
/// - `key`: JWK object with `kty == 'oct'`, `alg == 'A256CTR'`, `k`
/// - `iv`: base64url initialization vector
/// - `hashes`: map containing at least `sha256`
/// - `v`: version string (must be `'v2'`)
class ValidatedEncryptedFile {
  ValidatedEncryptedFile._(this.json);

  /// The validated JSON map, safe to embed as the `file` field in a Matrix
  /// room event.
  final Map<String, dynamic> json;

  /// Attempts to parse and validate encrypted-file metadata from the
  /// serialized JSON string carried on an attachment.
  ///
  /// When [expectedMxcUri] is provided, the encrypted JSON's `url` field must
  /// match it exactly. This ensures the attachment link and the encrypted
  /// payload reference the same resource.
  ///
  /// Returns `null` if [jsonStr] is null, empty, not valid JSON, or does
  /// not satisfy the Matrix encrypted-file invariants.
  static ValidatedEncryptedFile? tryParse(
    String? jsonStr, {
    String? expectedMxcUri,
  }) {
    if (jsonStr == null || jsonStr.isEmpty) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } on FormatException {
      return null;
    }

    if (decoded is! Map<String, dynamic>) return null;

    if (!_isValidStructure(decoded, expectedMxcUri: expectedMxcUri)) {
      return null;
    }

    return ValidatedEncryptedFile._(decoded);
  }

  static bool _isValidStructure(
    Map<String, dynamic> map, {
    String? expectedMxcUri,
  }) {
    final url = map[encryptedFileFieldUrl];
    if (url is! String || !url.startsWith(matrixMxcUriScheme)) {
      return false;
    }

    if (expectedMxcUri != null && url != expectedMxcUri) return false;

    final key = map[encryptedFileFieldKey];
    if (key is! Map<String, dynamic>) return false;
    if (key[jsonWebKeyFieldKty] != jsonWebKeyType) return false;
    if (key[jsonWebKeyFieldAlg] != jsonWebKeyAlgorithm) return false;
    if (key[jsonWebKeyFieldK] is! String) return false;

    if (map[encryptedFileFieldIv] is! String) return false;

    final hashes = map[encryptedFileFieldHashes];
    if (hashes is! Map<String, dynamic>) return false;
    if (hashes[encryptedFileSha256Key] is! String) return false;

    if (map[encryptedFileFieldVersion] != encryptedFileInfoVersion) {
      return false;
    }

    return true;
  }
}
