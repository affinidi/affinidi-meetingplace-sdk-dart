import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../shared/credential_constants.dart';
import '../../shared/credential_signer.dart';
import '../model/vrc_constants.dart';
import '../model/vrc_credential_subject.dart';

/// Builds signed Verifiable Relationship Credentials (VRCs).
///
/// Uses W3C Data Model v2 with an ecdsa-jcs-2019 (Data Integrity) proof.
abstract final class VrcBuilder {
  /// Builds and signs a VRC.
  ///
  /// - [issuerDid] — DID of the issuer.
  /// - [subject] — The two-party relationship subject (`from` / `to`).
  /// - [issuerDidManager] — [DidManager] used to sign the credential.
  static Future<VerifiableCredential> build({
    required String issuerDid,
    required VrcCredentialSubject subject,
    required DidManager issuerDidManager,
  }) async {
    final unsigned = VcDataModelV2(
      context: JsonLdContext.fromJson([
        dmV2ContextUrl,
        RelationshipCredentialConstants.dataIntegrityV2Context,
        VrcConstants.contextVrc,
      ]),
      credentialSchema: [
        CredentialSchema(
          id: Uri.parse(
            VrcConstants.contextVrc.replaceFirst('.jsonld', '.json'),
          ),
          type: 'JsonSchemaValidator2018',
        ),
      ],
      id: Uri.parse('urn:uuid:${const Uuid().v4()}'),
      issuer: Issuer.uri(issuerDid),
      type: {
        RelationshipCredentialConstants.typeVerifiableCredential,
        VrcConstants.typeRelationshipCredential,
      },
      validFrom: DateTime.now().toUtc(),
      credentialSubject: [CredentialSubject.fromJson(subject.toJson())],
    );
    return CredentialSigner.sign(unsigned, issuerDidManager);
  }
}
