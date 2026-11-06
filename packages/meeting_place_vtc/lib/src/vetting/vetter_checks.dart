import 'package:ssi/ssi.dart';

import '../credentials/credential_fields.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/eddsa_jcs_2022.dart';
import '../proof/trust_task_signer.dart';
import 'vetting_card.dart';

/// The presentation in a vetter's `vetting/request#response` that shows
/// the applicant [domain] the vetter [signer] holds [roleCard]: made for
/// the request document [nonce] and signed for `authentication`.
Future<Map<String, dynamic>> vetterEligibilityPresentation({
  required Map<String, dynamic> roleCard,
  required String nonce,
  required String domain,
  required TrustTaskSigner signer,
}) => EddsaJcs2022.sign(
  {
    '@context': ['https://www.w3.org/ns/credentials/v2'],
    'type': ['VerifiablePresentation'],
    'holder': signer.did,
    'nonce': nonce,
    'domain': domain,
    'verifiableCredential': [roleCard],
  },
  signer: signer,
  purpose: ProofPurpose.authentication,
);

/// Why a vetter refuses an applicant's vetting card.
enum VettingCardRefusal {
  /// The card is not shaped as a vetting card.
  shape,

  /// The card was made for another session, vetter, community or applicant.
  binding,

  /// The card is not valid now, holds too long or outlives the session.
  expired,

  /// The applicant's signature does not verify.
  proof,

  /// A detail the session asks for is missing.
  missingClaim,

  /// The identity commitment does not match the card's details.
  commitment,
}

/// A vetting card the vetter did not accept.
class VettingCardException implements Exception {
  /// Creates a [VettingCardException].
  const VettingCardException(this.refusal, {this.detail});

  /// Why the card was refused.
  final VettingCardRefusal refusal;

  /// Which check failed, for diagnostics. Never a claim.
  final String? detail;

  @override
  String toString() =>
      'VettingCardException(${refusal.name}'
      '${detail == null ? '' : ': $detail'})';
}

/// How far the vetter's and the applicant's clocks may be apart.
const vettingClockSkew = Duration(seconds: 60);

/// Checks [card], which the applicant [applicantDid] sent the vetter
/// [vetterDid] in the session for [communityDid] with [challenge], ending
/// at [sessionExpiresAt], and returns its claims of [requiredClaims]: what
/// the vetter checks in person.
///
/// Throws [VettingCardException] when it is not bound to this session, not
/// valid at [now], not signed by the applicant for `assertionMethod`, lacks
/// a required claim, or its identity commitment does not match them.
Future<List<VettingCardClaim>> verifyVettingCard(
  Map<String, dynamic> card, {
  required String applicantDid,
  required String vetterDid,
  required String communityDid,
  required String challenge,
  required DateTime sessionExpiresAt,
  required List<String> requiredClaims,
  required DidResolver didResolver,
  required DateTime now,
}) async {
  final issuedAt = DateTime.tryParse('${card['issuedAt']}');
  final expiresAt = DateTime.tryParse('${card['expiresAt']}');
  final claims = _claims(card['claims']);
  final commitment = card['identityCommitment'];
  final salt = card['commitmentSalt'];
  if (!_cardTypes.every(credentialTypes(card).contains) ||
      card['id'] is! String ||
      card['cardVersion'] != 1 ||
      issuedAt == null ||
      expiresAt == null ||
      claims == null ||
      commitment is! String ||
      salt is! String) {
    throw const VettingCardException(VettingCardRefusal.shape);
  }

  if (card['publisher'] != applicantDid ||
      card['audience'] != vetterDid ||
      card['community'] != communityDid ||
      card['domain'] != communityDid ||
      card['challenge'] != challenge) {
    throw const VettingCardException(VettingCardRefusal.binding);
  }

  if (!expiresAt.isAfter(issuedAt) ||
      expiresAt.difference(issuedAt) > maxVettingCardValidity ||
      issuedAt.isAfter(now.add(vettingClockSkew)) ||
      now.isAfter(expiresAt.add(vettingClockSkew)) ||
      expiresAt.isAfter(sessionExpiresAt)) {
    throw const VettingCardException(VettingCardRefusal.expired);
  }

  try {
    await EddsaJcs2022.verify(
      card,
      purpose: ProofPurpose.assertionMethod,
      resolver: didResolver,
      expectedSigner: applicantDid,
    );
  } on MeetingPlaceVtcSDKException catch (error) {
    throw VettingCardException(
      VettingCardRefusal.proof,
      detail: error.code.value,
    );
  }

  final required = [
    for (final type in requiredClaims.toSet())
      switch (claims.where((claim) => claim.type == type).firstOrNull) {
        final VettingCardClaim claim => claim,
        null => throw VettingCardException(
          VettingCardRefusal.missingClaim,
          detail: type,
        ),
      },
  ];
  final expected = vettingIdentityCommitment(
    salt: salt,
    claims: required,
    identityTypes: requiredClaims,
  );
  if (expected != commitment) {
    throw const VettingCardException(VettingCardRefusal.commitment);
  }
  return required;
}

const _cardTypes = [
  'VerifiableDataStructure',
  'RelationshipCard',
  'VettingCard',
];

/// The card's claims, or null when they are not a list of typed values.
List<VettingCardClaim>? _claims(Object? json) {
  if (json is! List) return null;
  final claims = <VettingCardClaim>[];
  for (final claim in json) {
    if (claim case {'type': final String type, 'value': final Object value}) {
      claims.add(VettingCardClaim(type: type, value: value));
    } else {
      return null;
    }
  }
  return claims;
}
