import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../entity/contact_card.dart';

/// Convenience hash extension for ContactCard.
extension ContactCardHashX on ContactCard {
  String get profileHash =>
      sha256.convert(utf8.encode(jsonEncode(contactInfo))).toString();
}
