/// A persona whose keys the member's VTA holds: one `did:webvh` per
/// community.
class VtaPersona {
  /// Creates a [VtaPersona]. [signingKeyId] defaults to the `#key-0` the VTA
  /// names a persona's signing key.
  const VtaPersona({
    required this.did,
    required this.contextId,
    String? signingKeyId,
  }) : _signingKeyId = signingKeyId;

  /// The persona's DID.
  final String did;

  /// The VTA context the persona lives in.
  final String contextId;

  final String? _signingKeyId;

  /// Id of the persona's signing key on the VTA.
  String get signingKeyId => _signingKeyId ?? '$did#key-0';
}
