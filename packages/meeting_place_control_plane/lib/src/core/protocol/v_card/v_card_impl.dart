import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:json_annotation/json_annotation.dart';

import 'v_card.dart';

part 'v_card_impl.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class VCardImpl implements VCard {
  VCardImpl({required this.values});

  factory VCardImpl.fromJson(Map<String, dynamic> json) {
    return _$VCardImplFromJson(json);
  }

  factory VCardImpl.empty() {
    return VCardImpl(values: {});
  }

  @override
  final Map<dynamic, dynamic> values;

  @override
  Map<String, dynamic> toJson() {
    return _$VCardImplToJson(this);
  }

  @override
  String toHash() {
    return sha256.convert(utf8.encode(jsonEncode(values))).toString();
  }

  @override
  String toBase64({bool removePadding = false}) {
    final base64 = base64UrlEncode(utf8.encode(jsonEncode(values)));
    return removePadding ? removePaddingFromBase64(base64) : base64;
  }

  static VCard fromBase64(String base64, {bool addPadding = false}) {
    final base64Padded = addPadding ? 'base64=' : base64;
    final json = jsonDecode(utf8.decode(base64Decode(base64Padded)))
        as Map<String, dynamic>;

    return VCardImpl.fromJson({'values': json});
  }

  @override
  bool equals(VCard otherVCard) {
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
