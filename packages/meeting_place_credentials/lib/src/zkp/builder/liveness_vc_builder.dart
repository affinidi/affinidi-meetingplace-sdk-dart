import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../shared/credential_sdk_constants.dart';
import '../../shared/credential_signer.dart';
import '../model/liveness_credential_constants.dart';
import '../model/liveness_credential_subject.dart';
import '../model/liveness_evidence.dart';

/// Builds signed W3C liveness verifiable credentials.
abstract final class LivenessVcBuilder {
  static Future<VcDataModelV2> build({
    required String issuerDid,
    required String holderDid,
    required LivenessEvidence evidence,
    required DidManager issuerDidManager,
    Duration validFor = const Duration(days: 5),
  }) async {
    final validFrom = evidence.checkedAt.toUtc();
    final validUntil = validFrom.add(validFor);

    final unsigned = VcDataModelV2(
      context: JsonLdContext.fromJson([
        dmV2ContextUrl,
        CredentialsSDKConstants.dataIntegrityV2Context,
        LivenessCredentialConstants.contextLivenessCredential,
      ]),
      id: Uri.parse('urn:uuid:${const Uuid().v4()}'),
      issuer: Issuer.uri(issuerDid),
      type: {
        CredentialsSDKConstants.typeVerifiableCredential,
        LivenessCredentialConstants.typeLivenessCredential,
      },
      validFrom: validFrom,
      validUntil: validUntil,
      credentialSubject: [
        CredentialSubject.fromJson(
          LivenessCredentialSubject(
            holderDid: holderDid,
            evidence: evidence,
          ).toJson(),
        ),
      ],
    );

    return CredentialSigner.sign(unsigned, issuerDidManager);
  }
}
