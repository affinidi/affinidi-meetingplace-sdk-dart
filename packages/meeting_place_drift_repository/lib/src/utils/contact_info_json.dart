import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart' as model;

/// Extracts the profile picture value from [card]'s contactInfo so it can be
/// stored in a dedicated database column instead of inside the JSON blob.
String? extractProfilePic(model.ContactCard card) {
  final photo = card.contactInfo['photo'];
  return photo is String ? photo : null;
}

/// Encodes [card]'s contactInfo as JSON, excluding the 'photo' key so that
/// the profile picture is persisted separately via [extractProfilePic].
String encodeContactInfoJson(model.ContactCard card) {
  final info = Map<String, dynamic>.from(card.contactInfo)..remove('photo');
  return jsonEncode(info);
}

/// Decodes a JSON string back into a contactInfo map.
///
/// If [profilePic] is provided (non-null and non-empty), it is re-inserted
/// under the 'photo' key so that callers receive a fully-populated map.
Map<String, dynamic> decodeContactInfoJson(
  String contactInfoJson, {
  String? profilePic,
}) {
  final decoded = jsonDecode(contactInfoJson);
  final Map<String, dynamic> result;
  if (decoded is Map<String, dynamic>) {
    result = decoded;
  } else if (decoded is Map) {
    result = Map<String, dynamic>.from(decoded);
  } else {
    result = <String, dynamic>{};
  }

  if (profilePic != null && profilePic.isNotEmpty) {
    result['photo'] = profilePic;
  }

  return result;
}
