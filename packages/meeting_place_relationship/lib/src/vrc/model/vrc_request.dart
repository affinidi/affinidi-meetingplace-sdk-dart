import 'vrc_constants.dart';

/// A typed VRC issuance request received over VDIP.
class VrcRequest {
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

  final String senderDid;
  final String? proposalId;
  final Map<String, dynamic> credentialMeta;
  final Map<String, dynamic> credentialMetaData;

  String? get relationshipType =>
      credentialMetaData[VrcConstants.requestMetadataKeyRelationshipType]
          as String?;

  String? get channelId =>
      credentialMetaData[VrcConstants.requestMetadataKeyChannelId] as String?;

  String? get selectedIdentity =>
      credentialMetaData[VrcConstants.requestMetadataKeySelectedIdentity]
          as String?;

  String? get identityDid =>
      credentialMetaData[VrcConstants.requestMetadataKeyIdentityDid]
          as String? ??
      selectedIdentity;

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
