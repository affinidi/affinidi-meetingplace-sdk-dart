import 'package:ssi/ssi.dart';

import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/eddsa_jcs_2022.dart';
import '../status/status_list_client.dart';
import 'credential_fields.dart';

/// Checks a community's role card: the DTG Verifiable Authority Credential
/// a VTC issues, as itself, to grant one of its members a role, e.g.
///
/// ```json
/// {
///   "type": ["VerifiableCredential", "DTGCredential", "AuthorityCredential"],
///   "issuer": "<community DID>",
///   "credentialSubject": {
///     "id": "<member persona DID>",
///     "authority": {"scope": "<community DID>", "actions": ["role:admin"]}
///   }
/// }
/// ```
///
/// A role card names no status list: the community withdraws a role by
/// issuing a new card, so a card holds until its `validUntil`.
abstract final class CommunityRoleCard {
  /// The VC type of a role card.
  static const type = 'AuthorityCredential';

  /// The role of a community's administrators.
  static const adminRole = 'admin';

  /// The action a role card grants for [role], e.g. `role:admin`.
  static String action(String role) => 'role:$role';

  /// When [card] stops holding, or null when it does not say.
  static DateTime? validUntil(Map<String, dynamic> card) =>
      DateTime.tryParse('${card['validUntil']}');

  /// Verifies that [card] is [communityDid]'s grant of [role] in it to
  /// [holderDid], valid at [now], and signed by the community
  /// (`eddsa-jcs-2022`, `assertionMethod`) with a key [resolver] finds in
  /// its DID document.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when it is not.
  static Future<void> verify(
    Map<String, dynamic> card, {
    required String communityDid,
    required String holderDid,
    required String role,
    required DidResolver resolver,
    DateTime? now,
  }) async {
    if (!credentialTypes(card).contains(type)) {
      throw MeetingPlaceVtcSDKException.invalidDocument('not a role card');
    }
    if (credentialIssuer(card) != communityDid) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'role card of another community',
      );
    }
    if (!grants(
      card,
      communityDid: communityDid,
      holderDid: holderDid,
      role: role,
    )) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'role card does not grant the role',
      );
    }
    _checkValidity(card, now ?? DateTime.now());
    await EddsaJcs2022.verify(
      card,
      purpose: ProofPurpose.assertionMethod,
      resolver: resolver,
      expectedSigner: communityDid,
    );
  }

  /// Whether [card], as it reads, grants [holderDid] [role] in
  /// [communityDid]. Neither its issuer, its validity nor its proof is
  /// checked: for a card the VTA verified when it kept it; [verify] checks
  /// one received.
  static bool grants(
    Map<String, dynamic> card, {
    required String communityDid,
    required String holderDid,
    required String role,
  }) {
    final grant = action(role);
    final subject = card['credentialSubject'];
    final subjects = subject is List ? subject : [subject];
    return subjects.any(
      (subject) => switch (subject) {
        {
          'id': final String id,
          'authority': {
            'scope': final String scope,
            'actions': final List<dynamic> actions,
          },
        } =>
          id == holderDid && scope == communityDid && actions.contains(grant),
        _ => false,
      },
    );
  }

  /// A role card always carries `validUntil`; one without is refused
  /// rather than taken to hold for ever.
  static void _checkValidity(Map<String, dynamic> card, DateTime now) {
    final validFrom = DateTime.tryParse('${card['validFrom']}');
    final validUntil = CommunityRoleCard.validUntil(card);
    const skew = StatusListClient.clockSkew;
    if (validUntil == null ||
        now.subtract(skew).isAfter(validUntil) ||
        (validFrom != null && now.add(skew).isBefore(validFrom))) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'role card not valid now',
      );
    }
  }
}
