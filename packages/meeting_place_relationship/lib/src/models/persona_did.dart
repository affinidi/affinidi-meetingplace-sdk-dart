/// A lightweight, SDK-owned representation of a persona identity.
///
/// Replaces app-level wrappers such as `MinimalPersona` or `Identity` so that
/// package APIs remain independent of any consumer app's internal types.
class PersonaDid {
  const PersonaDid({required this.did, required this.name});

  /// The decentralised identifier (DID) of this persona.
  final String did;

  /// The display name associated with this persona.
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonaDid && did == other.did && name == other.name;

  @override
  int get hashCode => Object.hash(did, name);

  @override
  String toString() => 'PersonaDid(did: $did, name: $name)';
}
