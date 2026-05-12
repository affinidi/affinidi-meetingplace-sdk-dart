import 'dart:convert';

import 'package:crypto/crypto.dart';

class MatrixUserIdBindingException implements Exception {
  MatrixUserIdBindingException({
    required this.did,
    required this.expectedMatrixUserId,
    required this.actualMatrixUserId,
  });

  final String did;
  final String expectedMatrixUserId;
  final String actualMatrixUserId;

  @override
  String toString() {
    return 'Matrix user ID binding mismatch for DID $did';
  }
}

String deriveMatrixUserId(String did, String serverName) {
  final localpart = sha256.convert(utf8.encode('$did|$serverName')).toString();
  return '@$localpart:$serverName';
}

void validateMatrixUserIdBinding({
  required String did,
  required String matrixUserId,
  required String serverName,
}) {
  final expectedMatrixUserId = deriveMatrixUserId(did, serverName);
  if (matrixUserId != expectedMatrixUserId) {
    throw MatrixUserIdBindingException(
      did: did,
      expectedMatrixUserId: expectedMatrixUserId,
      actualMatrixUserId: matrixUserId,
    );
  }
}
