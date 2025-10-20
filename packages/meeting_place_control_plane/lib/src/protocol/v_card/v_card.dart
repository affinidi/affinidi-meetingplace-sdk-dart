abstract interface class VCard {
  Map<dynamic, dynamic> get values;

  Map<String, dynamic> toJson();

  String toHash();

  String toBase64({bool removePadding = false});

  bool equals(VCard otherVCard);
}
