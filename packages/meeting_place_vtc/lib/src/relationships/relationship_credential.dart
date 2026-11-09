import 'package:uuid/uuid.dart';

import '../trust_task/trust_task_time.dart';

/// The relationship credential (VRC) a member issues about another member
/// of their community: a DTG `RelationshipCredential` from [issuerDid] about
/// [subjectDid], both the personas the two joined the community with.
///
/// The edge is attributed (`issuerScope: directed`): it names the members'
/// personas, which the community recognises, so other members can see it.
/// It carries no other DID. Unsigned: the VTA signs it as the persona for
/// `assertionMethod`.
Map<String, dynamic> relationshipCredential({
  required String issuerDid,
  required String subjectDid,
  DateTime? now,
}) => {
  '@context': [
    'https://www.w3.org/ns/credentials/v2',
    'https://registry.trustoverip.org/dtg/context/v1',
  ],
  'type': ['VerifiableCredential', 'DTGCredential', 'RelationshipCredential'],
  'id': 'urn:uuid:${const Uuid().v4()}',
  'issuer': issuerDid,
  'issuerScope': 'directed',
  'validFrom': formatTrustTaskTime(now ?? DateTime.now()),
  'credentialSubject': {'id': subjectDid},
};
