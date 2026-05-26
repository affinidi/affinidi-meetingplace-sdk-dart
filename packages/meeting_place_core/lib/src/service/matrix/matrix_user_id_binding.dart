import 'dart:convert';

import 'package:crypto/crypto.dart';

String deriveMatrixUserId(String did, String serverName) {
  final localpart = sha256.convert(utf8.encode('$did|$serverName')).toString();
  return '@$localpart:$serverName';
}
