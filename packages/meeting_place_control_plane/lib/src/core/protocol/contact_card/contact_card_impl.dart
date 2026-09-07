import 'dart:convert';

import 'contact_card.dart';

/// The default [ContactCard] implementation.
class ContactCardImpl implements ContactCard {
  /// Creates a new instance of [ContactCardImpl].
  ContactCardImpl({
    required this.did,
    required this.type,
    required this.contactInfo,
  });

  /// Creates a [ContactCardImpl] from the given JSON [json].
  ///
  /// Missing `did` and `type` fields default to an empty string.
  factory ContactCardImpl.fromJson(Map<String, dynamic> json) {
    return ContactCardImpl(
      did: json['did'] as String? ?? '',
      type: json['type'] as String? ?? '',
      contactInfo: (json['contactInfo'] as Map).cast<String, dynamic>(),
    );
  }

  /// Creates an empty [ContactCardImpl] with blank [did] and [type] and no
  /// [contactInfo].
  factory ContactCardImpl.empty() {
    return ContactCardImpl(did: '', type: '', contactInfo: {});
  }

  @override
  final String did;

  @override
  final String type;

  @override
  final Map<String, dynamic> contactInfo;

  @override
  Map<String, dynamic> toJson() {
    return {'did': did, 'type': type, 'contactInfo': contactInfo};
  }

  @override
  String toHash() {
    return base64Url.encode(utf8.encode(jsonEncode(toJson())));
  }

  @override
  String toBase64({bool removePadding = false}) {
    final encoded = const Base64Codec().encode(
      utf8.encode(jsonEncode(toJson())),
    );
    if (!removePadding) return encoded;
    return encoded.replaceAll('=', '');
  }

  @override
  bool equals(ContactCard other) {
    return did == other.did &&
        type == other.type &&
        jsonEncode(contactInfo) == jsonEncode(other.contactInfo);
  }

  /// Decodes a [ContactCardImpl] from its [toBase64] representation.
  ///
  /// Set [addPadding] to `true` when [base64] may be missing its trailing
  /// `=` padding characters.
  static ContactCardImpl fromBase64(String base64, {bool addPadding = false}) {
    final codec = const Base64Codec();
    final normalized = codec.decode(
      codec.normalize(addPadding ? _addPadding(base64) : base64),
    );
    final jsonMap = jsonDecode(utf8.decode(normalized)) as Map<String, dynamic>;
    return ContactCardImpl.fromJson(jsonMap);
  }

  static String _addPadding(String s) {
    final mod = s.length % 4;
    if (mod == 0) return s;
    return s.padRight(s.length + (4 - mod), '=');
  }
}
