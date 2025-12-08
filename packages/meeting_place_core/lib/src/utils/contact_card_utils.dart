import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../entity/contact_card.dart';

String contactCardHash(ContactCard card) {
  return sha256.convert(utf8.encode(jsonEncode(card.contactInfo))).toString();
}
