import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../extensions/jcs_canonicalized.dart';

part 'contact_card.g.dart';

/// A shareable, self-describing profile card exchanged between connected
/// parties.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ContactCard {
  /// Creates a [ContactCard] by decoding a base64url-encoded JSON payload.
  factory ContactCard.fromBase64(String base64) {
    final base64Codec = const Base64Codec();

    final normalized = base64Url.decode(base64Codec.normalize(base64));
    final jsonMap = jsonDecode(utf8.decode(normalized)) as Map<String, dynamic>;
    return ContactCard.fromJson(jsonMap);
  }

  /// Creates a [ContactCard] from its JSON representation.
  factory ContactCard.fromJson(Map<String, dynamic> json) {
    return _$ContactCardFromJson(json);
  }

  /// Creates a [ContactCard], stripping empty [contactInfo] entries and
  /// canonicalizing the remaining map.
  ContactCard({
    required this.did,
    required this.type,
    required Map<String, dynamic> contactInfo,
  }) : contactInfo = _stripEmpty(contactInfo).canonicalized();

  static Map<String, dynamic> _stripEmpty(Map<String, dynamic> map) =>
      Map.of(map)..removeWhere((_, value) => value == null || value == '');

  /// The DID of the party this contact card describes.
  final String did;

  /// The type of contact card, e.g. the kind of profile being shared.
  final String type;

  /// The card's profile fields, canonicalized and stripped of empty values.
  final Map<String, dynamic> contactInfo;

  /// A hash of [contactInfo], used to detect whether a card's profile has
  /// changed.
  late final String profileHash = sha256
      .convert(utf8.encode(contactInfo.toCanonicalJson()))
      .toString();

  /// Converts this [ContactCard] to its JSON representation.
  Map<String, dynamic> toJson() {
    return _$ContactCardToJson(this);
  }

  /// Encodes this [ContactCard] as base64url-encoded JSON.
  String toBase64({bool removePadding = false}) {
    final encoded = const Base64Codec().encode(
      utf8.encode(jsonEncode(toJson())),
    );
    if (!removePadding) return encoded;
    return encoded.replaceAll('=', '');
  }

  /// Whether [other] has the same [did], [type], and [contactInfo] as this
  /// card.
  bool equals(ContactCard other) {
    const eq = DeepCollectionEquality();
    return did == other.did &&
        type == other.type &&
        eq.equals(contactInfo, other.contactInfo);
  }
}
