import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ssi/ssi.dart' show KeyType, PublicKey;

/// Derives `opaqueId = base32(sha256(authPublicKeyBytes)).lower()` (no padding).
///
/// * Ed25519 → 32 raw verify-key bytes
/// * P-256   → 65-byte uncompressed point (04 || x || y)
String opaqueIdFromPublicKey(PublicKey pk) {
  final authBytes = pk.type == KeyType.p256
      ? uncompressP256(pk.bytes)
      : pk.bytes;
  final digest = sha256.convert(authBytes);
  return _base32Encode(Uint8List.fromList(digest.bytes)).toLowerCase();
}

/// Decompresses a 33-byte P-256 compressed public key to a 65-byte uncompressed
/// point (0x04 || x || y) using the P-256 curve parameters.
///
/// P-256: y² = x³ − 3x + b  (mod p), where p ≡ 3 (mod 4),
/// so y = rhs^((p+1)/4) mod p.
Uint8List uncompressP256(Uint8List compressed) {
  assert(compressed.length == 33, 'Expected 33-byte P-256 compressed key');
  assert(
    compressed[0] == 0x02 || compressed[0] == 0x03,
    'Expected 0x02 or 0x03 prefix',
  );

  final p = BigInt.parse(
    'ffffffff00000001000000000000000000000000ffffffffffffffffffffffff',
    radix: 16,
  );
  final b = BigInt.parse(
    '5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b',
    radix: 16,
  );

  final x = _bytesToBigInt(compressed.sublist(1));
  final x3 = x.modPow(BigInt.from(3), p);
  final ax = ((p - BigInt.from(3)) * x) % p;
  final rhs = (x3 + ax + b) % p;
  var y = rhs.modPow((p + BigInt.one) >> 2, p);

  if (y.isOdd != (compressed[0] == 0x03)) y = p - y;

  return Uint8List.fromList([
    0x04,
    ..._bigIntToBytes32(x),
    ..._bigIntToBytes32(y),
  ]);
}

BigInt _bytesToBigInt(Uint8List bytes) {
  var result = BigInt.zero;
  for (final b in bytes) {
    result = (result << 8) | BigInt.from(b);
  }
  return result;
}

Uint8List _bigIntToBytes32(BigInt n) {
  var hex = n.toRadixString(16);
  if (hex.length.isOdd) hex = '0$hex';
  hex = hex.padLeft(64, '0');
  final out = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

// RFC 4648 base32 encoding (no padding, uppercase → caller lowercases).
String _base32Encode(Uint8List data) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  final buf = StringBuffer();
  var buffer = 0;
  var bitsLeft = 0;
  for (final byte in data) {
    buffer = (buffer << 8) | byte;
    bitsLeft += 8;
    while (bitsLeft >= 5) {
      bitsLeft -= 5;
      buf.write(alphabet[(buffer >> bitsLeft) & 0x1f]);
    }
  }
  if (bitsLeft > 0) buf.write(alphabet[(buffer << (5 - bitsLeft)) & 0x1f]);
  return buf.toString();
}
