/// Shared credential type constants for all relationship credentials.
///
/// R-Card specific constants live in `RCardConstants`.
/// VRC specific constants live in `VrcConstants`.
class RelationshipCredentialConstants {
  RelationshipCredentialConstants._();

  static const w3cLdV1 = 'w3c/ldv1';
  static const w3cV1 = 'w3c/v1';
  static const w3cV2 = 'w3c/v2';
  static const dataIntegrityV2Context =
      'https://w3id.org/security/data-integrity/v2';

  static Set<String> get supportedFormats => {w3cV1, w3cLdV1, w3cV2};

  static const typeVerifiableCredential = 'VerifiableCredential';
}
