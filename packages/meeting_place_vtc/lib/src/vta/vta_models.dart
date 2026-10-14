/// A persona whose keys the member's VTA holds: one `did:webvh` per
/// community.
class VtaPersona {
  /// Creates a [VtaPersona].
  const VtaPersona({required this.did, required this.contextId});

  /// The persona's DID.
  final String did;

  /// The VTA context the persona lives in.
  final String contextId;

  /// Id of the persona's signing key. The VTA names it `#key-0`.
  String get signingKeyId => '$did#key-0';
}
