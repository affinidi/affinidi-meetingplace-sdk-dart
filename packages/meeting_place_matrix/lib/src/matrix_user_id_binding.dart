import 'dart:convert';

import 'package:crypto/crypto.dart';

String deriveMatrixUserId(String did, String serverName) {
  final localpart = sha256.convert(utf8.encode('$did|$serverName')).toString();
  return '@$localpart:$serverName';
}

String deriveMatrixDeviceId(String deviceId, String did, String homeserver) {
  return sha256.convert(utf8.encode('$deviceId|$did|$homeserver')).toString();
}

/// Finds the DID in [candidateDids] whose derived Matrix user ID matches
/// [matrixUserId] on [serverName]. Returns `null` if no candidate matches.
String? resolveSenderDidFromCandidates({
  required String matrixUserId,
  required String serverName,
  required Iterable<String> candidateDids,
}) {
  for (final did in candidateDids) {
    if (deriveMatrixUserId(did, serverName) == matrixUserId) return did;
  }
  return null;
}
