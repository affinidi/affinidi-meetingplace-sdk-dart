import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../proof/digest_multibase.dart';
import 'crockford_code.dart';

/// The longest a vetting card may hold.
const maxVettingCardValidity = Duration(minutes: 15);

/// The code both sides of a vetting session show, so the applicant and the
/// vetter can tell they are in the same session: the first 40 bits of
/// `SHA-256("vetting-session-match/v1\0" ‖ sessionDocumentId)` in Crockford
/// base32, e.g. `AWE8-JZ12`.
///
/// It never travels: the people compare it.
String vettingMatchCode(String sessionDocumentId) {
  final digest = sha256.convert([
    ...utf8.encode('vetting-session-match/v1'),
    0,
    ...utf8.encode(sessionDocumentId),
  ]).bytes;
  return crockfordCode(digest);
}

/// A claim on a vetting card, as the applicant states it.
class VettingCardClaim {
  /// Creates a [VettingCardClaim].
  const VettingCardClaim({required this.type, required this.value});

  /// The claim type, e.g. `name.legal`.
  final String type;

  /// The claim's value.
  final Object value;

  /// The claim as a card carries it. `selfAsserted` is the only provenance
  /// vetting defines.
  Map<String, dynamic> toJson() => {
    'type': type,
    'value': value,
    'provenance': 'selfAsserted',
  };
}

/// A fresh salt for an application's identity commitments: 32 random bytes,
/// base64url without padding. One per application, so every card in it
/// commits to the same identity.
String newCommitmentSalt() {
  final random = Random.secure();
  final bytes = [for (var i = 0; i < 32; i++) random.nextInt(256)];
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// The commitment a card makes to the claims of [identityTypes]: the
/// `digestMultibase` of `{"salt", "claims": [{"type", "value"}…]}`, the
/// first claim of each type, ordered by type.
///
/// Throws [ArgumentError] when a claim of [identityTypes] is missing.
String vettingIdentityCommitment({
  required String salt,
  required List<VettingCardClaim> claims,
  required List<String> identityTypes,
}) {
  final types = identityTypes.toSet().toList()..sort();
  return digestMultibase({
    'salt': salt,
    'claims': [
      for (final type in types)
        switch (claims.where((claim) => claim.type == type).firstOrNull) {
          final VettingCardClaim claim => {
            'type': claim.type,
            'value': claim.value,
          },
          null => throw ArgumentError.value(type, 'identityTypes', 'missing'),
        },
    ],
  });
}

/// A vetting card, not signed yet: what the applicant tells the vetter
/// about themselves in a `vetting/session`, to be signed as [publisher]
/// (`eddsa-jcs-2022`, `assertionMethod`).
///
/// The commitment covers the claims of [identityTypes], the session's
/// `requiredClaims`. Throws [ArgumentError] when one is missing or
/// [validity] is not within [maxVettingCardValidity].
Map<String, dynamic> unsignedVettingCard({
  required String id,
  required String publisher,
  required String audience,
  required String community,
  required String challenge,
  required String domain,
  required DateTime issuedAt,
  required Duration validity,
  required List<VettingCardClaim> claims,
  required List<String> identityTypes,
  required String salt,
}) {
  if (validity <= Duration.zero || validity > maxVettingCardValidity) {
    throw ArgumentError.value(validity, 'validity', 'out of range');
  }
  return {
    'type': ['VerifiableDataStructure', 'RelationshipCard', 'VettingCard'],
    'id': id,
    'publisher': publisher,
    'cardVersion': 1,
    'audience': audience,
    'community': community,
    'challenge': challenge,
    'domain': domain,
    'issuedAt': issuedAt.toUtc().toIso8601String(),
    'expiresAt': issuedAt.add(validity).toUtc().toIso8601String(),
    'claims': [for (final claim in claims) claim.toJson()],
    'identityCommitment': vettingIdentityCommitment(
      salt: salt,
      claims: claims,
      identityTypes: identityTypes,
    ),
    'commitmentSalt': salt,
  };
}

/// The digest a vetter's statement names a card, or a session document, by:
/// the `digestMultibase` of [document] without its proof.
String vettingDigest(Map<String, dynamic> document) =>
    digestMultibase({...document}..remove('proof'));
