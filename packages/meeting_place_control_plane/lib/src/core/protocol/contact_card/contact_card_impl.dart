import 'dart:convert';

import 'contact_card.dart';

class ContactCardImpl implements ContactCard {
  ContactCardImpl({required this.contactInfo});

  factory ContactCardImpl.fromJson(Map<String, dynamic> json) {
    return ContactCardImpl(
        contactInfo: (json['contactInfo'] as Map).cast<String, dynamic>());
  }

  factory ContactCardImpl.empty() {
    return ContactCardImpl(contactInfo: {});
  }

  @override
  final Map<String, dynamic> contactInfo;

  @override
  Map<String, dynamic> toJson() {
    return {
      'contactInfo': contactInfo,
    };
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
    return jsonEncode(contactInfo) == jsonEncode(other.contactInfo);
  }

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
