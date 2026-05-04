/// Shared credential type constants for all credentials.
///
/// R-Card specific constants live in `RCardConstants`.
/// VRC specific constants live in `VrcConstants`.
class CredentialsSDKConstants {
  CredentialsSDKConstants._();

  /// Format identifier for W3C LD Data Model v1 credentials.
  static const w3cLdV1 = 'w3c/ldv1';

  /// Format identifier for W3C Data Model v1 credentials.
  static const w3cV1 = 'w3c/v1';

  /// Format identifier for W3C Data Model v2 credentials.
  static const w3cV2 = 'w3c/v2';

  /// W3C Data Integrity v2 JSON-LD context URI.
  static const dataIntegrityV2Context =
      'https://w3id.org/security/data-integrity/v2';

  /// The set of credential format identifiers accepted by this SDK.
  static Set<String> get supportedFormats => {w3cV1, w3cLdV1, w3cV2};

  /// The base W3C credential type value present on all VCs.
  static const typeVerifiableCredential = 'VerifiableCredential';
}
