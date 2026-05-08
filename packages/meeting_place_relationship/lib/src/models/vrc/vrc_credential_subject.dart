import 'vrc_party.dart';

/// The credential subject of a Verifiable Relationship Credential (VRC).
///
/// Describes the two parties in the relationship: [from] (the issuer's
/// party) and [to] (the counterpart's party).
class VrcCredentialSubject {
  const VrcCredentialSubject({required this.from, required this.to});

  /// The party issuing the VRC.
  final VrcParty from;

  /// The counterpart in the relationship.
  final VrcParty to;

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
