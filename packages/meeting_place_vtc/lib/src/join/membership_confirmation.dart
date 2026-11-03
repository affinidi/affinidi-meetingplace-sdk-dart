import 'package:uuid/uuid.dart';

import '../proof/digest_multibase.dart';
import '../trust_task/trust_task_time.dart';

/// The credential a member issues back to their community once admitted:
/// a DTG `MembershipCredential` from the persona about the community, bound
/// to the community's own card by its digest, which completes the
/// membership on the community's side (`vtc/members/vmc/0.1`).
///
/// [communityCard] is the membership card the community issued to
/// [personaDid]; the credential lasts as long as it does. Unsigned: the VTA
/// signs it as the persona for `assertionMethod`.
Map<String, dynamic> memberMembershipCredential({
  required String personaDid,
  required String communityDid,
  required Map<String, dynamic> communityCard,
  DateTime? now,
}) {
  // The community digests its card without its proof, so a re-signed card
  // keeps the same digest.
  final unproven = Map<String, dynamic>.of(communityCard)..remove('proof');
  return {
    '@context': [
      'https://www.w3.org/ns/credentials/v2',
      'https://registry.trustoverip.org/dtg/context/v1',
    ],
    'type': ['VerifiableCredential', 'DTGCredential', 'MembershipCredential'],
    'id': 'urn:uuid:${const Uuid().v4()}',
    'issuer': personaDid,
    'issuerScope': 'directed',
    'validFrom': formatTrustTaskTime(now ?? DateTime.now()),
    if (communityCard['validUntil'] case final String validUntil)
      'validUntil': validUntil,
    'credentialSubject': {
      'id': communityDid,
      'digestMultibase': digestMultibase(unproven),
    },
  };
}
