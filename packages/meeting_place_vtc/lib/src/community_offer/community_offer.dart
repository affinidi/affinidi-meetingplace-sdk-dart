import 'package:ssi/ssi.dart';

import '../credentials/community_role_card.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/eddsa_jcs_2022.dart';
import '../sign_in/sign_in_agent.dart';
import '../status/status_list_client.dart';
import '../vta/vta_models.dart';

/// The statement that makes a Meeting Place offer point to a community: a
/// community admin, as their persona, vouches that a phrase leads to the
/// community, and shows the role card the community issued them.
///
/// ```json
/// {
///   "type": "CommunityOfferStatement",
///   "issuer": "<admin persona DID>",
///   "communityDid": "<community DID>",
///   "phrase": "<the offer's phrase>",
///   "validUntil": "<the role card's validUntil>",
///   "roleCard": {"…": "the community's role card, unchanged"},
///   "proof": {"…": "the persona's eddsa-jcs-2022 proof"}
/// }
/// ```
///
/// The one proof covers the phrase, the community and the role card
/// together, so none of them can be swapped. Anyone can copy a published
/// statement, but it only ever leads to the community it names, under the
/// phrase it names, until it expires.
abstract final class CommunityOffer {
  /// The key of the statement in the offer's contact card `contactInfo`.
  static const contactInfoKey = 'org.openvtc.community-offer';

  /// The statement's type.
  static const statementType = 'CommunityOfferStatement';

  /// Has [agent] sign, as the admin [persona], a statement that [phrase]
  /// leads to [communityDid], showing [roleCard], the community's grant of
  /// the admin role to the persona.
  ///
  /// The statement lasts as long as the role card. It is verified as a
  /// member would before it is returned, so a statement members would
  /// refuse is never published.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the VTA refuses to sign, or
  /// the statement does not verify, e.g. as the card grants no admin role.
  static Future<Map<String, dynamic>> sign({
    required PersonaSigningAgent agent,
    required VtaPersona persona,
    required String communityDid,
    required String phrase,
    required Map<String, dynamic> roleCard,
    DidResolver? resolver,
  }) async {
    final validUntil = roleCard['validUntil'];
    if (validUntil is! String) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'role card without validUntil',
      );
    }
    final statement = await agent.signDocument(
      keyId: persona.signingKeyId,
      document: {
        'type': statementType,
        'issuer': persona.did,
        'communityDid': communityDid,
        'phrase': phrase,
        'validUntil': validUntil,
        'roleCard': roleCard,
      },
      purpose: ProofPurpose.assertionMethod.value,
    );
    await verify(statement, phrase: phrase, resolver: resolver);
    return statement;
  }

  /// Verifies that [statement] vouches, under [phrase], for a community,
  /// and returns the community's DID.
  ///
  /// [phrase] is the phrase the offer was registered under, as the control
  /// plane returned it: a statement copied to another phrase is refused.
  /// The statement must be signed by its issuer (`eddsa-jcs-2022`,
  /// `assertionMethod`), valid at [now], and carry a role card in which the
  /// community grants the issuer its admin role.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when it does not.
  static Future<String> verify(
    Map<String, dynamic> statement, {
    required String phrase,
    DidResolver? resolver,
    DateTime? now,
  }) async {
    final (issuer, communityDid, roleCard) = switch (statement) {
      {
        'type': statementType,
        'issuer': final String issuer,
        'communityDid': final String communityDid,
        'roleCard': final Map<String, dynamic> roleCard,
      } =>
        (issuer, communityDid, roleCard),
      _ => throw MeetingPlaceVtcSDKException.invalidDocument(
        'not a community offer statement',
      ),
    };
    if (statement['phrase'] != phrase) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'statement for another phrase',
      );
    }
    final at = now ?? DateTime.now();
    final validUntil = DateTime.tryParse('${statement['validUntil']}');
    if (validUntil == null ||
        at.subtract(StatusListClient.clockSkew).isAfter(validUntil)) {
      throw MeetingPlaceVtcSDKException.invalidDocument('statement expired');
    }

    final didResolver = resolver ?? UniversalDIDResolver.defaultResolver;
    await EddsaJcs2022.verify(
      statement,
      purpose: ProofPurpose.assertionMethod,
      resolver: didResolver,
      expectedSigner: issuer,
    );
    await CommunityRoleCard.verify(
      roleCard,
      communityDid: communityDid,
      holderDid: issuer,
      role: CommunityRoleCard.adminRole,
      resolver: didResolver,
      now: at,
    );
    return communityDid;
  }
}
