import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../protocol/contact_card/contact_card.dart';

/// Convenience hash extension for ContactCard.
extension ContactCardHashX on ContactCard {
  String get profileHash =>
      sha256.convert(utf8.encode(jsonEncode(contactInfo))).toString();
}
