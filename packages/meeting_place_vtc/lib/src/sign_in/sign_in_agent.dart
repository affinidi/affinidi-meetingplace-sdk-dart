/// The member's VTA, as a sign-in uses it: it signs the `identify` and
/// `grant` documents as the persona, whose key never leaves the VTA.
abstract interface class SignInAgent {
  /// DID of the VTA. The approval decision is addressed to it.
  String get vtaDid;

  /// Has the VTA sign [unsignedEnvelope] as the persona of vault entry
  /// [entryId] (`vault/sign-trust-task/0.2`), with optional extensions such
  /// as the person's approval.
  ///
  /// Throws a `MeetingPlaceVtcSDKException` when the VTA refuses or cannot be
  /// reached.
  Future<Map<String, dynamic>> signTrustTask({
    required String entryId,
    required Map<String, dynamic> unsignedEnvelope,
    Map<String, dynamic>? ext,
  });
}

/// The persona a member signs in as, and the VTA vault entry that lets the
/// VTA sign as it.
class SignInPersona {
  /// Creates a [SignInPersona].
  const SignInPersona({required this.did, required this.entryId});

  /// The persona's DID, the member's identity in the community.
  final String did;

  /// Id of the persona's `did-self-issued` vault entry.
  final String entryId;
}
