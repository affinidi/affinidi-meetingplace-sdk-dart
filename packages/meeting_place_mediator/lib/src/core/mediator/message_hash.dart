import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Returns the hash a mediator identifies a stored [message] by: the SHA-256
/// of its packed JSON.
String hashMessage(Map<String, dynamic> message) {
  return sha256.convert(utf8.encode(jsonEncode(message))).toString();
}
