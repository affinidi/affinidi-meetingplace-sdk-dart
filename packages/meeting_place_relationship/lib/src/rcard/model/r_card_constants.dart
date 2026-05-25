/// R-Card specific credential type constants and schema URIs.
class RCardConstants {
  RCardConstants._();

  /// The W3C credential type value for R-Card credentials.
  static const typeRCard = 'RelationshipCard';

  /// JSON-LD context URI for the R-Card credential shape.
  static const contextRCard =
      'https://schema.affinidi.io/TRelationshipCardV1R0.jsonld';

  /// JSON schema URI for the R-Card credential shape.
  static const schemaRCard =
      'https://schema.affinidi.io/TRelationshipCardV1R0.json';

  /// Monotonically increasing schema version for `RCard` storage.
  static const receivedRCardVersion = 1;
}
