/// Host that path-form flow types of a trigger link resolve against.
const triggerLinkHost = 'link.trustoverip.org';

/// Type base of the VTC sign-in flow (Key Grant, `auth/oob/*`).
const signInFlowType = 'https://$triggerLinkHost/vti/flow/sign-in';

/// Type base of the agent-claim flow.
const vtaClaimFlowType = 'https://$triggerLinkHost/vti/flow/vta-claim';

/// Name of the sign-in flow, as returned on an accepted link.
const signInFlow = 'sign-in';

/// A flow a reader knows by its type URI, without the version segment.
class TriggerFlow {
  /// Creates a [TriggerFlow].
  const TriggerFlow({
    required this.flow,
    required this.typeBase,
    required this.isDraft,
    required this.expRequired,
    required this.supportedVersions,
    this.allowedDidMethods,
    this.implemented = false,
  });

  /// Plain label returned on accept, e.g. `sign-in`.
  final String flow;

  /// Type URI without its `/MAJOR.MINOR` segment.
  final String typeBase;

  /// A draft flow accepts only the listed minors; a stable one any minor of
  /// a listed major whose minors are null.
  final bool isDraft;

  /// Whether a link of this flow must carry `_exp`.
  final bool expRequired;

  /// Accepted minors per major. A null list means any minor.
  final Map<int, List<int>?> supportedVersions;

  /// DID methods (`did:webvh`, …) accepted as the sender, or null for any.
  final List<String>? allowedDidMethods;

  /// Whether this app carries the flow through. A known flow it does not is
  /// answered "needs a newer version".
  final bool implemented;

  /// Whether this reader accepts version [major].[minor] of the flow.
  bool accepts(int major, int minor) {
    if (!supportedVersions.containsKey(major)) return false;
    final minors = supportedVersions[major];
    if (minors == null) return !isDraft;
    return minors.contains(minor);
  }
}

/// How a trigger link is read.
class TriggerLinkConfig {
  /// Creates a [TriggerLinkConfig].
  const TriggerLinkConfig({
    required this.flows,
    this.skewSeconds = 60,
    this.maxLinkLength = 1536,
    this.aliasSchemes = const [],
  });

  /// What Meeting Place reads: sign-in is carried through; an agent claim is
  /// known, so it is read and answered "needs a newer version".
  static const meetingPlace = TriggerLinkConfig(
    flows: [
      TriggerFlow(
        flow: signInFlow,
        typeBase: signInFlowType,
        isDraft: true,
        expRequired: true,
        allowedDidMethods: ['did:webvh', 'did:web'],
        supportedVersions: {
          0: [1],
        },
        implemented: true,
      ),
      TriggerFlow(
        flow: 'vta-claim',
        typeBase: vtaClaimFlowType,
        isDraft: true,
        expRequired: true,
        allowedDidMethods: ['did:webvh', 'did:web'],
        supportedVersions: {
          0: [1],
        },
      ),
    ],
  );

  /// Flows this reader knows.
  final List<TriggerFlow> flows;

  /// Allowance for the phone's clock when checking `_exp`.
  final int skewSeconds;

  /// Longest link read, in code points.
  final int maxLinkLength;

  /// Schemes besides `https` that are this app's own.
  final List<String> aliasSchemes;
}
