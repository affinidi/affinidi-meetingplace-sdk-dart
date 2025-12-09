import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../entity/contact_card.dart';

String contactCardHash(ContactCard card) {
  return sha256.convert(utf8.encode(jsonEncode(card.contactInfo))).toString();
}

/// Convenience hash extension for ContactCard.
extension ContactCardHashX on ContactCard {
  String get profileHash =>
      sha256.convert(utf8.encode(jsonEncode(contactInfo))).toString();
}
