import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ssi/ssi.dart';

/// Multihash header for SHA2-256: code `0x12`, digest length `0x20`.
const _sha256MultihashHeader = [0x12, 0x20];

/// Returns the `digestMultibase` of a JSON value: the base58btc multibase of
/// the SHA2-256 multihash of its JCS canonical form.
///
/// Used for a sign-in grant's `contextDigest` and for the payload digest of
/// a consent decision.
String digestMultibase(Object? json) {
  final digest = sha256.convert(utf8.encode(JcsUtil.canonicalize(json)));
  return toMultiBase(
    Uint8List.fromList([..._sha256MultihashHeader, ...digest.bytes]),
  );
}
