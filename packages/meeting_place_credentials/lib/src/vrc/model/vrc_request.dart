import 'vrc_constants.dart';

/// Upper bound on the length of a peer-supplied identity DID accepted from
/// VDIP proposal metadata, so a maliciously oversized value cannot be used
/// downstream as an identity-lookup key or in VC issuance calls.
const _maxIdentityDidLength = 512;

/// Minimal DID URI shape check (`did:<method>:<method-specific-id>`), per
/// the W3C DID Core ABNF. Deliberately permissive on the method-specific-id
/// charset: this rejects obviously spoofed/malformed input, not a full
/// per-method conformance check.
final RegExp _identityDidPattern = RegExp(r'^did:[a-z0-9]+:[A-Za-z0-9._:%-]+$');

/// Upper bound on the length of a peer-supplied identity display name
/// accepted from VDIP proposal metadata.
const _maxIdentityNameLength = 256;

/// Control characters (C0/C1) and Unicode bidi override/embedding
/// characters that must not appear in a peer-supplied display name, since
/// they can be used to visually spoof how the name renders in UI.
final RegExp _identityNameStripPattern = RegExp(
  '[\\x00-\\x1F\\x7F-\\x9F\\u202A-\\u202E\\u2066-\\u2069]',
);

/// Validates [value] as a DID, returning it unchanged if valid or `null`
/// otherwise. Never mutates the value: callers use it as an exact-match
/// identity-lookup key and feed it verbatim into VC issuance calls.
String? _validateIdentityDid(String? value) {
  if (value == null) return null;
  if (value.length > _maxIdentityDidLength) return null;
  if (!_identityDidPattern.hasMatch(value)) return null;
  return value;
}

/// Sanitizes [value] for display: strips control and bidi override/
/// embedding characters, then caps the length.
String? _sanitizeIdentityName(String? value) {
  if (value == null) return null;
  final stripped = value.replaceAll(_identityNameStripPattern, '');
  if (stripped.length <= _maxIdentityNameLength) return stripped;
  return stripped.substring(0, _maxIdentityNameLength);
}

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
  ///
  /// Prefer [identityDid] which falls back to this value.
  ///
  /// Validated the same way as [identityDid]: `null` if not DID-shaped or
  /// too long, since this peer-supplied value is also used as a fallback
  /// identity-lookup key.
  String? get selectedIdentity => _validateIdentityDid(
    credentialMetaData[VrcConstants.requestMetadataKeySelectedIdentity]
        as String?,
  );

  /// Identity DID from the proposal metadata. Falls back to [selectedIdentity]
  /// for backward compatibility with older request payloads.
  ///
  /// This is peer-supplied data received over VDIP: `null` if it is missing,
  /// not DID-shaped, or exceeds the accepted length, rather than passing a
  /// malformed value through to callers that use it as an exact-match
  /// identity-lookup key and feed it verbatim into VC issuance calls.
  String? get identityDid =>
      _validateIdentityDid(
        credentialMetaData[VrcConstants.requestMetadataKeyIdentityDid]
            as String?,
      ) ??
      selectedIdentity;

  /// Display name of the identity from the proposal metadata, or `null`.
  ///
  /// This is peer-supplied data received over VDIP: control characters and
  /// Unicode bidi override/embedding characters are stripped and the length
  /// is capped, so a malicious peer cannot use it to spoof how the name
  /// renders in UI or to exhaust memory.
  String? get identityName => _sanitizeIdentityName(
    credentialMetaData[VrcConstants.requestMetadataKeyIdentityName] as String?,
  );

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
