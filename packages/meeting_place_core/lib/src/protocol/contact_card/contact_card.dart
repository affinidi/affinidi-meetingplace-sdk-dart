import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../extensions/jcs_canonicalized.dart';

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
  }) : contactInfo = _stripEmpty(contactInfo).canonicalized();

  static Map<String, dynamic> _stripEmpty(Map<String, dynamic> map) =>
      Map.of(map)..removeWhere((_, value) => value == null || value == '');

  final String did;
  final String type;

  final Map<String, dynamic> contactInfo;
  late final String profileHash = sha256
      .convert(utf8.encode(contactInfo.toCanonicalJson()))
      .toString();

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

  bool equals(ContactCard other) {
    const eq = DeepCollectionEquality();
    return did == other.did &&
        type == other.type &&
        eq.equals(contactInfo, other.contactInfo);
  }
}
