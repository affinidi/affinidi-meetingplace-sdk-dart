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
    required this.requirementsDigest,
    this.description,
    this.invitationRequired = false,
    this.asksForCredentials = false,
    this.asksForVetting = false,
  });

  /// The criterion's id within the community.
  final String id;

  /// The digest a submission names to apply under this criterion.
  final String requirementsDigest;

  /// Whether meeting it admits at once or goes to review.
  final JoinAdmission admission;

  /// The community's own words for the criterion, if any.
  final String? description;

  /// Whether only invited applicants meet it.
  final bool invitationRequired;

  /// Whether it asks the applicant to present credentials.
  final bool asksForCredentials;

  /// Whether it asks the applicant to be vetted in person.
  final bool asksForVetting;

  /// Whether an applicant with no invitation, credentials or vetting can
  /// meet it: the only criteria this wallet applies under.
  bool get isOpen =>
      !invitationRequired && !asksForCredentials && !asksForVetting;
}

/// A profile detail a community asks for with an application.
class JoinAttributeRequest {
  /// Creates a [JoinAttributeRequest].
  const JoinAttributeRequest({
    required this.type,
    this.required = true,
    this.purpose,
  });

  /// The claim type, e.g. `name` or `email`.
  final String type;

  /// Whether an application without it is refused.
  final bool required;

  /// Why the community asks, in its own words, if it says.
  final String? purpose;
}

/// A profile detail sent with an application.
class JoinAttribute {
  /// Creates a [JoinAttribute].
  const JoinAttribute({required this.type, required this.value});

  /// The claim type, as the community asked for it.
  final String type;

  /// The claim's value.
  final Object value;

  /// The attribute as `vtc/join-requests/submit/0.3` carries it.
  Map<String, dynamic> toJson() => {'type': type, 'value': value};
}

/// What a community asks of applicants (`vtc/join-requests/manifest/0.4`).
class JoinManifest {
  /// Creates a [JoinManifest].
  const JoinManifest({
    required this.community,
    required this.criteria,
    this.name,
    this.requestedAttributes = const [],
    this.listsNewMembers,
  });

  /// The community and where it takes Trust Tasks.
  final VtcCommunityEndpoint community;

  /// The ways into the community. Empty when it is not accepting
  /// applications.
  final List<JoinCriterion> criteria;

  /// The community's display name, if its manifest gives one.
  final String? name;

  /// The profile details the community asks for with an application.
  final List<JoinAttributeRequest> requestedAttributes;

  /// Whether the community lists a new member in its member directory
  /// (`directoryDisclosure.newCard.listing`), or null when it does not say.
  final bool? listsNewMembers;

  /// The community's DID.
  String get communityDid => community.did;

  /// The way in this wallet applies under: the first open criterion, in the
  /// community's order, or null when there is none.
  JoinCriterion? get openCriterion =>
      criteria.where((criterion) => criterion.isOpen).firstOrNull;

  /// Whether this wallet can apply: one way in needs no invitation,
  /// credentials or vetting. Requested profile details are the caller's to
  /// gather.
  bool get canApply => openCriterion != null;

  /// Whether an application under [openCriterion] is admitted at once.
  bool get admitsAtOnce => openCriterion?.admission == JoinAdmission.automatic;
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
    this.membershipCard,
    this.roleCard,
    this.role,
  });

  /// The membership card the community issued to the persona, as a JSON
  /// verifiable credential, or null when it delivers it later.
  final Map<String, dynamic>? membershipCard;

  /// The role credential the community issued, or null.
  final Map<String, dynamic>? roleCard;

  /// The cards the community issued, membership card first.
  List<Map<String, dynamic>> get credentials => [?membershipCard, ?roleCard];

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
