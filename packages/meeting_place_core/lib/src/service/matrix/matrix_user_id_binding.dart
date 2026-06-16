import 'dart:convert';

import 'package:crypto/crypto.dart';

String deriveMatrixUserId(String did, String serverName) {
  final localpart = sha256.convert(utf8.encode('$did|$serverName')).toString();
  return '@$localpart:$serverName';
}

String deriveMatrixDeviceId(String deviceId, String did, String homeserver) {
  return sha256.convert(utf8.encode('$deviceId|$did|$homeserver')).toString();
}
