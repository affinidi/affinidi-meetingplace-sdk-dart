import '../persona_did.dart';

/// The credential subject of a Verifiable Relationship Credential (VRC).
///
/// Describes the two parties in the relationship: [from] (the issuer's
/// persona) and [to] (the counterpart's persona).
class VrcCredentialSubject {
  const VrcCredentialSubject({required this.from, required this.to});

  /// The persona of the party issuing the VRC.
  final PersonaDid from;

  /// The persona of the counterpart in the relationship.
  final PersonaDid to;

  Map<String, dynamic> toJson() => {
    'from': {'did': from.did, 'name': from.name},
    'to': {'did': to.did, 'name': to.name},
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VrcCredentialSubject && from == other.from && to == other.to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'VrcCredentialSubject(from: $from, to: $to)';
}
