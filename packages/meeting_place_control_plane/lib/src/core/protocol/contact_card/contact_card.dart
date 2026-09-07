/// A contact card exchanged between participants during offer acceptance,
/// carrying the identity and connection details of one party.
abstract interface class ContactCard {
  /// The DID of the party this contact card represents.
  String get did;

  /// The contact card type.
  String get type;

  /// Additional connection details, such as transport-specific metadata.
  Map<String, dynamic> get contactInfo;

  /// Converts this [ContactCard] into a JSON map.
  Map<String, dynamic> toJson();

  /// Returns a hash derived from this contact card's JSON representation.
  String toHash();

  /// Encodes this contact card's JSON representation as base64.
  ///
  /// The [removePadding] flag controls whether trailing `=` padding
  /// characters are stripped from the result.
  String toBase64({bool removePadding = false});

  /// Whether this contact card is equal to [other].
  bool equals(ContactCard other);
}
