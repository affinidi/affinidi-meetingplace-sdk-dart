import 'dart:convert';

class ContactCard {
  ContactCard({
    required this.did,
    required this.type,
    required this.schema,
    required this.contactInfo,
  });

  factory ContactCard.fromJson(Map<String, dynamic> json) {
    return ContactCard(
      did: json['did'] as String,
      type: json['type'] as String,
      schema: json['schema'] as String,
      contactInfo: (json['contactInfo'] as Map).cast<String, dynamic>(),
    );
  }

  final String did;
  final String type;
  final String schema;
  final Map<String, dynamic> contactInfo;

  Map<String, dynamic> toJson() {
    return {
      'did': did,
      'type': type,
      'schema': schema,
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
