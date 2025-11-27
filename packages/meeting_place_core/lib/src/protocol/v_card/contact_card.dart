import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'contact_card.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ContactCard {
  factory ContactCard.fromBase64(String base64, {bool addPadding = false}) {
    final base64Padded = addPadding ? 'base64=' : base64;
    final json = jsonDecode(utf8.decode(base64Decode(base64Padded)))
        as Map<String, dynamic>;

    return ContactCard.fromJson({'values': json});
  }

  factory ContactCard.fromJson(Map<String, dynamic> json) {
    return _$ContactCardFromJson(json);
  }

  ContactCard({
    required this.did,
    required this.contactType,
    required this.info,
  });

  final String did;
  final String contactType;
  final Map<String, dynamic> info;

  String get displayName => 'Anonymous';

  Map<String, dynamic> toJson() {
    return _$ContactCardToJson(this);
  }

  // TODO: remove
  factory ContactCard.empty() {
    return ContactCard(
      did: '',
      contactType: '',
      info: {},
    );
  }

  String toHash() {
    return sha256.convert(utf8.encode(jsonEncode(info))).toString();
  }

  String toBase64({bool removePadding = false}) {
    final base64 = base64UrlEncode(utf8.encode(jsonEncode(info)));
    return removePadding ? removePaddingFromBase64(base64) : base64;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person && other.name == name && other.age == age;
  }

  @override
  int get hashCode => Object.hash(name, age);

  bool equals(ContactCard otherVCard) {
    return otherVCard.toHash() == toHash();
  }

  String removePaddingFromBase64(String base64Input) {
    var endIndex = base64Input.length;

    while (endIndex > 0 && base64Input[endIndex - 1] == '=') {
      endIndex--;
    }

    return base64Input.substring(0, endIndex);
  }
}
