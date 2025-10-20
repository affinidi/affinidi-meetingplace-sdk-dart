import 'dart:convert';

import 'package:crypto/crypto.dart';

String hashDid(String did) {
  return sha256.convert(utf8.encode(did)).toString();
}

List<String> hashDids(List<String> dids) {
  return dids.map(hashDid).toList();
}
