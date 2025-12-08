abstract interface class ContactCard {
  Map<String, dynamic> get contactInfo;

  Map<String, dynamic> toJson();

  String toHash();

  String toBase64({bool removePadding = false});

  bool equals(ContactCard other);
}
