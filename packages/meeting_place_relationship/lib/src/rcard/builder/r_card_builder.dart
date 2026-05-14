import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../shared/credential_constants.dart';
import '../model/j_card.dart';
import '../model/r_card_constants.dart';
import '../model/r_card_subject.dart';

/// Builds signed R-Card Verifiable Credentials.
///
/// Uses W3C Data Model v1 with an ecdsa-jcs-2019 (Data Integrity) proof.
/// Contact data is embedded as an RFC 7095 jCard in the credential subject.
abstract final class RCardBuilder {
  /// Builds and signs an R-Card VC.
  ///
  /// - [issuerDid] — DID of the issuer.
  /// - [subjectDid] — DID of the credential subject.
  /// - [subject] — Contact fields to embed as a jCard.
  /// - [issuerDidManager] — [DidManager] used to sign the credential.
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
