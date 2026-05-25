/// A party (DID + display name) referenced in a Verifiable
/// Relationship Credential.
///
/// Used for the `from` and `to` fields of `VrcCredentialSubject`.
class VrcParty {
  /// Creates a [VrcParty] with the given [did] and [name].
  const VrcParty({required this.did, required this.name});

  /// Deserialises a [VrcParty] from a JSON map.
  factory VrcParty.fromJson(Map<String, dynamic> json) =>
      VrcParty(did: json['did'] as String, name: json['name'] as String);

  /// The DID of the party.
  final String did;

  /// Display name of the party.
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VrcParty && did == other.did && name == other.name;

  @override
  int get hashCode => Object.hash(did, name);

  @override
  String toString() => 'VrcParty(did: $did, name: $name)';
}
