import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../models/credential_constants.dart';
import '../models/r_card/j_card.dart';
import '../models/r_card/r_card_constants.dart';
import '../models/r_card/r_card_subject.dart';
import 'credential_signer.dart';

/// Builds signed R-Card Verifiable Credentials.
///
/// Uses W3C Data Model v2 with an ecdsa-jcs-2019 (Data Integrity) proof.
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
    final unsigned = VcDataModelV2(
      context: JsonLdContext.fromJson([
        dmV2ContextUrl,
        RelationshipCredentialConstants.dataIntegrityV2Context,
        RCardConstants.contextRCard,
      ]),
      id: Uri.parse('urn:uuid:${const Uuid().v4()}'),
      issuer: Issuer.uri(issuerDid),
      type: {
        RelationshipCredentialConstants.typeVerifiableCredential,
        RCardConstants.typeRCard,
      },
      validFrom: DateTime.now().toUtc(),
      credentialSubject: [
        CredentialSubject.fromJson({
          'id': subjectDid,
          'card': JCard.encode(subject),
        }),
      ],
    );
    return CredentialSigner.sign(unsigned, issuerDidManager);
  }
}
