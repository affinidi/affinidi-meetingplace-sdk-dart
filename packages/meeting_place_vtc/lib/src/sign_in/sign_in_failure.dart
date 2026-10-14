/// Why a sign-in could not go ahead, for a screen to word.
enum SignInFailure {
  /// The code or the request has expired.
  expired,

  /// The code cannot be used.
  invalid,

  /// The code needs a newer version of the app, or the agent does.
  update,

  /// The community could not be reached.
  unreachable,

  /// The code is from a community this phone has not joined.
  notAMember,

  /// The community's DID document offers no wallet sign-in.
  noSignIn,

  /// Another device already scanned this code.
  alreadyClaimed,

  /// The community no longer knows the request, e.g. the page was refreshed.
  notFound,

  /// The community declined for another reason.
  refused,

  /// The identity is not an administrator, for an operator console sign-in.
  notAnAdmin,

  /// An answer failed a check, so it was not believed.
  badAnswer,

  /// What was typed is not two digits; nothing was sent.
  badNumber,

  /// The community says the number is wrong; the request is over.
  wrongNumber,

  /// The agent has no sign-in entry for this persona and community.
  noVaultEntry,

  /// The agent does not know this phone as a registered device.
  notEnrolledDevice,

  /// The agent has no approval key for this phone.
  noUvKey,

  /// The agent got no approval from this phone.
  uvRequired,

  /// The person cancelled the biometric prompt; nothing was sent.
  uvCancelled,

  /// The approval key is gone because enrolled biometrics changed.
  uvKeyLost,

  /// The phone could not use its approval key.
  uvUnavailable,

  /// The agent already signed this approval.
  grantReplayed,

  /// The persona's DID document cannot approve sign-ins.
  assertionMethodMissing,

  /// The member's agent declined.
  agentRefused,

  /// The member's agent needs an update to sign in to websites.
  agentNeedsUpdate,

  /// The member's agent could not be reached.
  agentUnreachable,
}

/// A sign-in step that could not complete.
class SignInException implements Exception {
  /// Creates a [SignInException].
  const SignInException(this.failure, {this.detail, this.responded = false});

  /// Why the step failed.
  final SignInFailure failure;

  /// Which check failed, for diagnostics. Never a link, key or document.
  final String? detail;

  /// Whether the grant may already have reached the community. The request
  /// must then not be cancelled, or the community would cancel a sign-in it
  /// already approved.
  final bool responded;

  @override
  String toString() =>
      'SignInException(${failure.name}${detail == null ? '' : ': $detail'})';
}

/// Why the phone's biometric approval key could not sign.
enum UserVerificationError {
  /// The person cancelled the biometric prompt.
  cancelled,

  /// The key is gone, e.g. because enrolled biometrics changed.
  lost,

  /// The phone could not use the key.
  unavailable,
}

/// Thrown by a user-verification signer that could not sign.
class UserVerificationException implements Exception {
  /// Creates a [UserVerificationException].
  const UserVerificationException(this.error);

  /// Why signing failed.
  final UserVerificationError error;

  @override
  String toString() => 'UserVerificationException(${error.name})';
}
