/// VRC specific credential type constants and schema URIs.
class VrcConstants {
  VrcConstants._();

  /// The W3C credential type value for VRC credentials.
  static const typeRelationshipCredential = 'RelationshipCredential';

  /// Metadata key for the relationship type in a VRC issuance request.
  static const requestMetadataKeyRelationshipType = 'relationship_type';

  /// Metadata key for the channel DID in a VRC issuance request.
  static const requestMetadataKeyChannelId = 'channel_id';

  /// Legacy metadata key for the selected identity DID.
  static const requestMetadataKeySelectedIdentity = 'selected_identity';

  /// Metadata key for the identity DID in a VRC issuance request.
  static const requestMetadataKeyIdentityDid = 'identity_did';

  /// Metadata key for the identity display name in a VRC issuance request.
  static const requestMetadataKeyIdentityName = 'identity_name';

  /// Relationship type value for chat-participant relationships.
  static const requestRelationshipTypeChatParticipant = 'chat_participant';

  /// JSON-LD context URI for the VRC credential shape.
  static const contextVrc =
      'https://schema.affinidi.io/TRelationshipCredentialV1R0.jsonld';
}
