/// A party (DID + display name) referenced in a Verifiable
/// Relationship Credential.
///
/// Used for the `from` and `to` fields of `VrcCredentialSubject`.
class VrcParty {
  const VrcParty({required this.did, required this.name});

  factory VrcParty.fromJson(Map<String, dynamic> json) =>
      VrcParty(did: json['did'] as String, name: json['name'] as String);

  final String did;
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
