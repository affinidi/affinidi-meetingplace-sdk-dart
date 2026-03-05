import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

class ChatUtils {
  static String getChatId({
    required String did,
    required String otherPartyDid,
  }) {
    return '$did-$otherPartyDid';
  }

  static String contactHash(ContactCard card) {
    return sha256.convert(utf8.encode(jsonEncode(card.contactInfo))).toString();
  }
}
