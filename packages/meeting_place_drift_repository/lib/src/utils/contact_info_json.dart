import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart' as model;

String encodeContactInfoJson(model.ContactCard card) {
  return jsonEncode(card.contactInfo);
}

Map<String, dynamic> decodeContactInfoJson(String contactInfoJson) {
  final decoded = jsonDecode(contactInfoJson);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }

  if (decoded is Map) {
    return Map<String, dynamic>.from(decoded);
  }

  return <String, dynamic>{};
}
