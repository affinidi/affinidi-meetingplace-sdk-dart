import '../proof/trust_task_signer.dart';
import '../vtc/vtc_resolver.dart';
import 'sign_in_agent.dart';

/// Which page of the community the browser is signing in to.
enum SignInAudience {
  /// The member portal, `/members/`.
  member,

  /// The operator console, `/admin/`.
  admin,
}

/// What the browser reported about itself, as relayed by the community.
///
/// Not verified by the wallet: show it as reported by the community.
class SignInRequester {
  /// Creates a [SignInRequester].
  const SignInRequester({
    required this.browser,
    required this.os,
    required this.location,
    required this.sameNetwork,
    required this.createdAt,
  });

  /// Browser family, or `unknown`.
  final String browser;

  /// Operating system, or `unknown`.
  final String os;

  /// Approximate city and country, or `unknown`.
  final String location;

  /// Whether the browser and this phone share a network.
  final bool sameNetwork;

  /// When the browser opened the request, as reported.
  final String createdAt;
}

/// A sign-in request this phone has claimed.
///
/// Holds the throwaway approver key, which lives only in memory and is
/// dropped with the session.
class ClaimedSignIn {
  /// Creates a [ClaimedSignIn].
  ClaimedSignIn({
    required this.requestId,
    required this.vtc,
    required this.decisionDeadline,
    required this.audience,
    required this.approverKey,
    required this.step1,
  });

  /// The community's request handle.
  final String requestId;

  /// The community and its endpoints.
  final VtcEndpoints vtc;

  /// Seconds since the epoch by which the sign-in must be decided.
  final int decisionDeadline;

  /// Whether this signs in to the member portal or the operator console.
  final SignInAudience audience;

  /// The throwaway key (`K_a`) that signs what this phone sends.
  final Ed25519DidKeySigner approverKey;

  /// The community's signed answer to the claim.
  final Map<String, dynamic> step1;

  /// Whether the grant may have reached the community. A responded sign-in
  /// is never cancelled.
  bool responded = false;

  /// The website the person is signing in to.
  String get origin => vtc.signInOrigin;
}

/// A sign-in the community has identified: everything the approval screen
/// shows and the grant needs.
class ProvedSignIn {
  /// Creates a [ProvedSignIn].
  const ProvedSignIn({
    required this.claimed,
    required this.persona,
    required this.step2,
    required this.sessionKey,
    required this.requester,
    this.signingScope,
  });

  /// The claimed request.
  final ClaimedSignIn claimed;

  /// The persona the community identified.
  final SignInPersona persona;

  /// The community's whole signed step-2 answer, as received. The grant's
  /// `contextDigest` covers it.
  final Map<String, dynamic> step2;

  /// The browser's key (`K_b`) the grant lets act as the member.
  final String sessionKey;

  /// What the browser reported about itself.
  final SignInRequester requester;

  /// The task families the grant lets [sessionKey] sign for as the persona,
  /// as the community offered them; null for none beyond signing in.
  final List<String>? signingScope;
}
