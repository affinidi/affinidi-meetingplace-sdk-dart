import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'contact_card.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ContactCard {
  factory ContactCard.fromBase64(String base64) {
    final base64Codec = const Base64Codec();

    final normalized = base64Url.decode(base64Codec.normalize(base64));
    final jsonMap = jsonDecode(utf8.decode(normalized)) as Map<String, dynamic>;
    return ContactCard.fromJson(jsonMap);
  }

  factory ContactCard.fromJson(Map<String, dynamic> json) {
    return _$ContactCardFromJson(json);
  }

  ContactCard({
    required this.did,
    required this.type,
    required Map<String, dynamic> contactInfo,
  }) : contactInfo = _sortMap(contactInfo);

  final String did;
  final String type;
  final Map<String, dynamic> contactInfo;

  Map<String, dynamic> toJson() {
    return _$ContactCardToJson(this);
  }

  String toBase64({bool removePadding = false}) {
    final encoded = const Base64Codec().encode(
      utf8.encode(jsonEncode(toJson())),
    );
    if (!removePadding) return encoded;
    return encoded.replaceAll('=', '');
  }

  String get profileHash =>
      sha256.convert(utf8.encode(jsonEncode(contactInfo))).toString();

  static Map<String, dynamic> _sortMap(Map<String, dynamic> map) {
    final sorted = <String, dynamic>{};
    final keys = map.keys.toList()..sort();
    for (final key in keys) {
      final value = map[key];
      if (value is Map<String, dynamic>) {
        sorted[key] = _sortMap(value);
      } else if (value is List) {
        sorted[key] = value
            .map((e) => e is Map<String, dynamic> ? _sortMap(e) : e)
            .toList();
      } else {
        sorted[key] = value;
      }
    }
    return sorted;
  }

  bool equals(ContactCard other) {
    const eq = DeepCollectionEquality();
    return did == other.did &&
        type == other.type &&
        eq.equals(contactInfo, other.contactInfo);
  }
}
