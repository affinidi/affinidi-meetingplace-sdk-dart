import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../shared/credential_constants.dart';
import '../model/j_card.dart';
import '../model/r_card_constants.dart';
import '../model/r_card_subject.dart';

abstract final class RCardBuilder {
  static Future<VerifiableCredential> build({
    required String issuerDid,
    required String subjectDid,
    required RCardSubject subject,
    required DidManager issuerDidManager,
  }) async {
    final unsigned = VcDataModelV1(
      context: JsonLdContext.fromJson([
        dmV1ContextUrl,
        RelationshipCredentialConstants.dataIntegrityV2Context,
        RCardConstants.contextRCard,
      ]),
      id: Uri.parse('urn:uuid:${const Uuid().v4()}'),
      issuer: Issuer.uri(issuerDid),
      type: {
        RelationshipCredentialConstants.typeVerifiableCredential,
        RCardConstants.typeRCard,
      },
      issuanceDate: DateTime.now().toUtc(),
      credentialSubject: [
        CredentialSubject.fromJson({
          'id': subjectDid,
          'card': JCard.encode(subject),
        }),
      ],
    );

    final assertionMethod = issuerDidManager.assertionMethod.firstOrNull;
    if (assertionMethod == null) {
      throw StateError(
        'DidManager has no assertionMethod keys available for signing',
      );
    }

    final signer = await issuerDidManager.getSigner(assertionMethod);
    return LdVcDm1Suite().issue(
      unsignedData: unsigned,
      proofGenerator: DataIntegrityEcdsaJcsGenerator(signer: signer),
    );
  }
}
