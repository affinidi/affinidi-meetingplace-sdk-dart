import '../vtc/vtc_resolver.dart';

/// How a community decides on an applicant who meets a criterion.
enum JoinAdmission {
  /// Admitted on submission.
  automatic,

  /// Referred to the community's administrators.
  review,
}

/// One way into a community, as its join manifest states it.
class JoinCriterion {
  /// Creates a [JoinCriterion].
  const JoinCriterion({
    required this.id,
    required this.admission,
    this.description,
    this.invitationRequired = false,
    this.asksForCredentials = false,
  });

  /// The criterion's id within the community.
  final String id;

  /// Whether meeting it admits at once or goes to review.
  final JoinAdmission admission;

  /// The community's own words for the criterion, if any.
  final String? description;

  /// Whether only invited applicants meet it.
  final bool invitationRequired;

  /// Whether it asks the applicant to present credentials or be vetted.
  final bool asksForCredentials;

  /// Whether an applicant with no invitation and no credentials can meet it.
  bool get isOpen => !invitationRequired && !asksForCredentials;
}

/// What a community asks of applicants (`vtc/join-requests/manifest/0.3`).
class JoinManifest {
  /// Creates a [JoinManifest].
  const JoinManifest({
    required this.community,
    required this.criteria,
    this.name,
    this.requiredAttributes = const [],
  });

  /// The community and where it takes Trust Tasks.
  final VtcCommunityEndpoint community;

  /// The ways into the community. Empty when it is not accepting
  /// applications.
  final List<JoinCriterion> criteria;

  /// The community's display name, if its manifest gives one.
  final String? name;

  /// Attribute types the community requires with an application, e.g. a
  /// name. This wallet supplies none, so such a community refuses it.
  final List<String> requiredAttributes;

  /// The community's DID.
  String get communityDid => community.did;

  /// Whether this wallet can apply: the community accepts applications, one
  /// way in needs neither an invitation nor credentials, and no attribute is
  /// required.
  bool get canApply =>
      criteria.any((criterion) => criterion.isOpen) &&
      requiredAttributes.isEmpty;

  /// Whether an application meeting only open criteria is admitted at once.
  bool get admitsAtOnce => criteria.any(
    (criterion) =>
        criterion.isOpen && criterion.admission == JoinAdmission.automatic,
  );
}

/// The community's answer to a join request.
sealed class JoinVerdict {
  const JoinVerdict({required this.requestId});

  /// The community's id of the request, to ask about it later.
  final String requestId;
}

/// The applicant is a member.
class JoinAdmitted extends JoinVerdict {
  /// Creates a [JoinAdmitted].
  const JoinAdmitted({
    required super.requestId,
    required this.credentials,
    this.role,
  });

  /// The membership card and role credential the community issued, as JSON
  /// verifiable credentials. Empty when the community delivers them later.
  final List<Map<String, dynamic>> credentials;

  /// The member's role in the community, e.g. `member`.
  final String? role;
}

/// The request waits for the community's administrators.
class JoinPending extends JoinVerdict {
  /// Creates a [JoinPending].
  const JoinPending({required super.requestId});
}

/// The community turned the request down.
class JoinDenied extends JoinVerdict {
  /// Creates a [JoinDenied].
  const JoinDenied({required super.requestId, this.reason});

  /// The community's reason, in its own words, if it gave one.
  final String? reason;
}

/// The community needs more than this wallet sent, such as credentials.
class JoinNeedsMore extends JoinVerdict {
  /// Creates a [JoinNeedsMore].
  const JoinNeedsMore({required super.requestId});
}

/// Where a join request stands (`vtc/join-requests/status/0.1`).
enum JoinRequestStatus {
  /// Waiting for a decision.
  pending,

  /// Put off by the administrators; still open.
  deferred,

  /// Admitted: the applicant is a member.
  approved,

  /// Turned down.
  rejected,

  /// Withdrawn by the applicant.
  withdrawn;

  /// Whether the community may still decide.
  bool get isOpen => this == pending || this == deferred;
}
