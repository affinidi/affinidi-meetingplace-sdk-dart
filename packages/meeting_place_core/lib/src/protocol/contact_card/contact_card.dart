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
    required this.contactInfo,
  });

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
      sha256.convert(utf8.encode(_sortedJson(contactInfo))).toString();

  static String _sortedJson(dynamic value) {
    if (value is Map) {
      final sortedKeys = value.keys.toList()
        ..sort((a, b) => a.toString().compareTo(b.toString()));
      final entries = sortedKeys
          .map((k) => '"$k":${_sortedJson(value[k])}')
          .join(',');
      return '{$entries}';
    }
    if (value is List) {
      return '[${value.map(_sortedJson).join(',')}]';
    }
    return jsonEncode(value);
  }

  bool equals(ContactCard other) {
    const eq = DeepCollectionEquality();
    return did == other.did &&
        type == other.type &&
        eq.equals(contactInfo, other.contactInfo);
  }
}
