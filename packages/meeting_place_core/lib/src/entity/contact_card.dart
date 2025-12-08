import 'dart:convert';

class ContactCard {
  ContactCard({
    required this.did,
    required this.type,
    required this.contactInfo,
  });

  factory ContactCard.fromJson(Map<String, dynamic> json) {
    return ContactCard(
      did: json['did'] as String,
      type: json['type'] as String,
      contactInfo: (json['contactInfo'] as Map).cast<String, dynamic>(),
    );
  }

  static ContactCard fromBase64(String base64, {bool addPadding = false}) {
    final codec = const Base64Codec();
    final normalized = codec.decode(
      codec.normalize(addPadding ? _addPadding(base64) : base64),
    );
    final jsonMap = jsonDecode(utf8.decode(normalized)) as Map<String, dynamic>;
    return ContactCard.fromJson(jsonMap);
  }

  final String did;
  final String type;
  final Map<String, dynamic> contactInfo;

  String get notificationValue {
    String firstName = _getPathValue(['n', 'given']);
    if (firstName.trim().isNotEmpty) return firstName;
    String email = _getPathValue(['email', 'type', 'work']);
    if (email.trim().isNotEmpty) return email;
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'did': did,
      'type': type,
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

  String _getPathValue(List<String> pathKeys) {
    Map<dynamic, dynamic> parent = contactInfo;
    for (final key in pathKeys) {
      final element = parent[key];
      if (element == null) return '';
      if (key == pathKeys.last && element is String) return element;
      if (element is Map<dynamic, dynamic>) {
        parent = element;
      }
    }
    return '';
  }

  static String _addPadding(String s) {
    final mod = s.length % 4;
    if (mod == 0) return s;
    return s.padRight(s.length + (4 - mod), '=');
  }
}

class InfoCard {
  InfoCard({
    required this.did,
    required this.type,
    required this.contactInfo,
  });

  final String did;
  final String type;
  final Map<String, dynamic> contactInfo;

  String get notificationValue {
    String firstName = _getPathValue(['n', 'given']);
    if (firstName.trim().isNotEmpty) return firstName;
    String email = _getPathValue(['email', 'type', 'work']);
    if (email.trim().isNotEmpty) return email;
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'did': did,
      'type': type,
      'contactInfo': contactInfo,
    };
  }

  String _getPathValue(List<String> pathKeys) {
    Map<dynamic, dynamic> parent = contactInfo;
    for (final key in pathKeys) {
      final element = parent[key];
      if (element == null) return '';
      if (key == pathKeys.last && element is String) return element;
      if (element is Map<dynamic, dynamic>) {
        parent = element;
      }
    }
    return '';
  }
}
