import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';

class GeneratedProofSigner implements VtaAuthSigner {
  GeneratedProofSigner._({required List<int> seed, required this.didKey})
    : _seed = List<int>.unmodifiable(seed),
      verificationMethod = '$didKey#${didKey.substring('did:key:'.length)}';

  final List<int> _seed;
  final String didKey;
  final String verificationMethod;

  static final _ed25519 = Ed25519();
  static final _sha256 = Sha256();

  static Future<GeneratedProofSigner> fromSeedHex(String seedHex) async {
    final seed = _parseHex(seedHex);
    if (seed.length != 32) {
      throw const FormatException('HOLDER_SEED_HEX must decode to 32 bytes');
    }
    final didMultibase = await _didKeyMultibaseFromSeed(seed);
    return GeneratedProofSigner._(seed: seed, didKey: 'did:key:$didMultibase');
  }

  @override
  Future<Map<String, dynamic>> createProof({
    required Map<String, dynamic> trustTask,
    required String operation,
  }) async {
    final proofConfig = <String, dynamic>{
      'type': 'DataIntegrityProof',
      'cryptosuite': 'eddsa-jcs-2022',
      'created': DateTime.now().toUtc().toIso8601String(),
      'verificationMethod': verificationMethod,
      'proofPurpose': 'authentication',
    };

    final canonicalDoc = _canonicalizeJson(trustTask);
    final canonicalProofConfig = _canonicalizeJson(proofConfig);

    final proofDigest = (await _sha256.hash(
      utf8.encode(canonicalProofConfig),
    )).bytes;
    final docDigest = (await _sha256.hash(utf8.encode(canonicalDoc))).bytes;
    final signingInput = <int>[...proofDigest, ...docDigest];

    final keyPair = await _ed25519.newKeyPairFromSeed(_seed);
    final signature = await _ed25519.sign(signingInput, keyPair: keyPair);
    final proofValue = 'z${_Base58.encode(signature.bytes)}';

    return <String, dynamic>{...proofConfig, 'proofValue': proofValue};
  }

  static List<int> _parseHex(String raw) {
    final normalized =
        raw.replaceAll(RegExp(r'\s+'), '').replaceAll('0x', '').trim();
    if (normalized.length.isOdd) {
      throw const FormatException('HOLDER_SEED_HEX must have even length');
    }
    final bytes = <int>[];
    for (var i = 0; i < normalized.length; i += 2) {
      final chunk = normalized.substring(i, i + 2);
      final value = int.tryParse(chunk, radix: 16);
      if (value == null) {
        throw FormatException('Invalid hex in HOLDER_SEED_HEX at position $i');
      }
      bytes.add(value);
    }
    return bytes;
  }

  static Future<String> _didKeyMultibaseFromSeed(List<int> seed) async {
    final keyPair = await _ed25519.newKeyPairFromSeed(seed);
    final publicKey = (await keyPair.extractPublicKey()).bytes;
    final multicodec = <int>[0xed, 0x01, ...publicKey];
    return 'z${_Base58.encode(multicodec)}';
  }

  static String _canonicalizeJson(dynamic value) {
    if (value == null || value is bool || value is num || value is String) {
      return jsonEncode(value);
    }
    if (value is List) {
      final items = value.map(_canonicalizeJson).join(',');
      return '[$items]';
    }
    if (value is Map) {
      final entries =
          value.entries
              .map((entry) => MapEntry(entry.key.toString(), entry.value))
              .toList(growable: false)
            ..sort((a, b) => a.key.compareTo(b.key));
      final buffer = StringBuffer('{');
      for (var i = 0; i < entries.length; i++) {
        if (i > 0) {
          buffer.write(',');
        }
        buffer.write(jsonEncode(entries[i].key));
        buffer.write(':');
        buffer.write(_canonicalizeJson(entries[i].value));
      }
      buffer.write('}');
      return buffer.toString();
    }
    throw FormatException('Unsupported JSON value type: ${value.runtimeType}');
  }
}

class _Base58 {
  static const _alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  static String encode(List<int> bytes) {
    if (bytes.isEmpty) {
      return '';
    }

    final digits = <int>[];
    for (final byte in bytes) {
      var carry = byte;
      for (var i = 0; i < digits.length; i++) {
        carry += digits[i] << 8;
        digits[i] = carry % 58;
        carry ~/= 58;
      }
      while (carry > 0) {
        digits.add(carry % 58);
        carry ~/= 58;
      }
    }

    final output = StringBuffer();
    for (final byte in bytes) {
      if (byte == 0) {
        output.write(_alphabet[0]);
      } else {
        break;
      }
    }
    for (final digit in digits.reversed) {
      output.write(_alphabet[digit]);
    }
    return output.toString();
  }
}
