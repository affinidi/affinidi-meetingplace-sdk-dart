/// R-Card specific credential type constants and schema URIs.
class RCardConstants {
  RCardConstants._();

  static const typeRCard = 'RelationshipCard';

  static const contextRCard =
      'https://schema.affinidi.io/TRelationshipCardV1R0.jsonld';

  static const schemaRCard =
      'https://schema.affinidi.io/TRelationshipCardV1R0.json';

  /// Monotonically increasing schema version for `ReceivedRCard` storage.
  static const receivedRCardVersion = 1;
}
