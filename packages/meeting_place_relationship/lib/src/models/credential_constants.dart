/// Shared credential type constants and schema URIs for VRC and R-Card credentials.
class RelationshipCredentialConstants {
  RelationshipCredentialConstants._();

  static const w3cLdV1 = 'w3c/ldv1';
  static const w3cV1 = 'w3c/v1';
  static const w3cV2 = 'w3c/v2';
  static const dataIntegrityV2Context =
      'https://w3id.org/security/data-integrity/v2';

  static Set<String> get supportedFormats => {w3cV1, w3cLdV1, w3cV2};

  static const typeVerifiableCredential = 'VerifiableCredential';
  static const typeRCard = 'RelationshipCard';
  static const typeRelationshipCredential = 'RelationshipCredential';

  static const contextVrc =
      'https://schema.affinidi.io/TRelationshipCredentialV1R0.jsonld';

  static const contextRCard =
      'https://schema.affinidi.io/TRelationshipCardV1R0.jsonld';
  static const schemaRCard =
      'https://schema.affinidi.io/TRelationshipCardV1R0.json';
}
