import 'dart:convert';

class ContactCard {
  factory ContactCard.fromBase64(String base64, {bool addPadding = false}) {
    final base64Padded = addPadding ? 'base64=' : base64;
    final json =
        jsonDecode(utf8.decode(base64Decode(base64Padded)))
            as Map<String, dynamic>;

    return ContactCard.fromJson(json);
  }

  factory ContactCard.fromJson(Map<String, dynamic> json) {
    return ContactCard(
      did: json['did'] as String,
      type: json['type'] as String,
      senderInfo: json['senderInfo'] as String,
      contactInfo: (json['contactInfo'] as Map).cast<String, dynamic>(),
    );
  }

  ContactCard({
    required this.did,
    required this.type,
    required this.senderInfo,
    required this.contactInfo,
  });

  final String did;
  final String type;
  final String senderInfo;
  final Map<String, dynamic> contactInfo;

  Map<String, dynamic> toJson() {
    return {
      'did': did,
      'type': type,
      'senderInfo': senderInfo,
      'contactInfo': contactInfo,
    };
  }

  String toBase64({bool removePadding = false}) {
    final encoded = const Base64Codec().encode(
      utf8.encode(jsonEncode(toJson())),
    );
    if (!removePadding) return encoded;
    return encoded.replaceAll('=', '');
  }

  bool equals(ContactCard other) {
    return did == other.did &&
        type == other.type &&
        jsonEncode(contactInfo) == jsonEncode(other.contactInfo);
  }
}
