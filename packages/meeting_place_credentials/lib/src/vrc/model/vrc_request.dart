import 'vrc_constants.dart';

/// A typed VRC issuance request received over VDIP.
class VrcRequest {
  /// Creates a [VrcRequest] from the given VDIP proposal data.
  VrcRequest({
    required this.senderDid,
    this.proposalId,
    Map<String, dynamic> credentialMeta = const <String, dynamic>{},
    Map<String, dynamic> credentialMetaData = const <String, dynamic>{},
  }) : credentialMeta = Map.unmodifiable(
         Map<String, dynamic>.from(credentialMeta),
       ),
       credentialMetaData = Map.unmodifiable(
         Map<String, dynamic>.from(credentialMetaData),
       );

  /// DID of the peer who sent the issuance request.
  final String senderDid;

  /// Optional proposal ID from the VDIP credential proposal message.
  final String? proposalId;

  /// Protocol-level metadata from the VDIP credential proposal.
  final Map<String, dynamic> credentialMeta;

  /// Application-level metadata embedded in the proposal (relationship type,
  /// channel ID, identity DID, etc.).
  final Map<String, dynamic> credentialMetaData;

  /// Relationship type string from the proposal metadata, or `null`.
  String? get relationshipType =>
      credentialMetaData[VrcConstants.requestMetadataKeyRelationshipType]
          as String?;

  /// Channel DID from the proposal metadata, or `null`.
  String? get channelId =>
      credentialMetaData[VrcConstants.requestMetadataKeyChannelId] as String?;

  /// Legacy selected identity DID from the proposal metadata, or `null`.
  /// Prefer [identityDid] which falls back to this value.
  String? get selectedIdentity =>
      credentialMetaData[VrcConstants.requestMetadataKeySelectedIdentity]
          as String?;

  /// Identity DID from the proposal metadata. Falls back to [selectedIdentity]
  /// for backward compatibility with older request payloads.
  String? get identityDid =>
      credentialMetaData[VrcConstants.requestMetadataKeyIdentityDid]
          as String? ??
      selectedIdentity;

  /// Display name of the identity from the proposal metadata, or `null`.
  String? get identityName =>
      credentialMetaData[VrcConstants.requestMetadataKeyIdentityName]
          as String?;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VrcRequest &&
          senderDid == other.senderDid &&
          proposalId == other.proposalId &&
          _mapsEqual(credentialMeta, other.credentialMeta) &&
          _mapsEqual(credentialMetaData, other.credentialMetaData);

  @override
  int get hashCode => Object.hash(
    senderDid,
    proposalId,
    Object.hashAllUnordered(
      credentialMeta.entries.map(
        (entry) => Object.hash(entry.key, entry.value),
      ),
    ),
    Object.hashAllUnordered(
      credentialMetaData.entries.map(
        (entry) => Object.hash(entry.key, entry.value),
      ),
    ),
  );

  @override
  String toString() {
    return 'VrcRequest('
        'senderDid: $senderDid, '
        'proposalId: $proposalId, '
        'credentialMetaData: $credentialMetaData)';
  }

  static bool _mapsEqual(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) return false;
    }
    return true;
  }
}
