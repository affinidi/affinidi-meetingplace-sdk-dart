/// VRC specific credential type constants and schema URIs.
class VrcConstants {
  VrcConstants._();

  static const typeRelationshipCredential = 'RelationshipCredential';

  static const requestMetadataKeyRelationshipType = 'relationship_type';
  static const requestMetadataKeyChannelId = 'channel_id';
  static const requestMetadataKeySelectedIdentity = 'selected_identity';
  static const requestMetadataKeyIdentityDid = 'identity_did';
  static const requestMetadataKeyIdentityName = 'identity_name';
  static const requestRelationshipTypeChatParticipant = 'chat_participant';

  static const contextVrc =
      'https://schema.affinidi.io/TRelationshipCredentialV1R0.jsonld';
}
