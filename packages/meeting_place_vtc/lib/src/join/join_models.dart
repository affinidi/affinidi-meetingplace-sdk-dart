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
    this.logoUrl,
    this.requestedAttributes = const [],
    this.listsNewMembers,
    this.directoryDisclosure,
  });

  /// The community and where it takes Trust Tasks.
  final VtcCommunityEndpoint community;

  /// The ways into the community. Empty when it is not accepting
  /// applications.
  final List<JoinCriterion> criteria;

  /// The community's display name, if its manifest gives one.
  final String? name;

  /// The community's logo, if its manifest gives an `https` one. Fetching it
  /// tells its host the reader's address.
  final Uri? logoUrl;

  /// The profile details the community asks for with an application.
  final List<JoinAttributeRequest> requestedAttributes;

  /// Whether the community lists a new member in its member directory
  /// (`directoryDisclosure.newCard.listing`), or null when it does not say.
  final bool? listsNewMembers;

  /// What the community's member directory would disclose about a member,
  /// or null when it offers no directory.
  final DirectoryDisclosure? directoryDisclosure;

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

/// Who a value in a community's member directory can reach, from the
/// narrowest audience to the widest.
enum DirectoryAudience {
  /// The community's administrators.
  admins,

  /// Members of a group the member is in.
  groups,

  /// Members the member is connected to.
  connections,

  /// Every member of the community.
  members,

  /// Anyone, beyond the community.
  public,
}

/// Who writes a member directory field's value.
enum DirectoryFieldSource {
  /// The member.
  member,

  /// The community's administrators: what the community asserts about the
  /// member, who reads it and cannot change it.
  admin,

  /// A credential the member holds.
  credential,

  /// The community, from other values.
  derived,
}

/// A field of a community's member directory, as the join manifest
/// discloses it.
class DirectoryField {
  /// Creates a [DirectoryField].
  const DirectoryField({
    required this.label,
    required this.source,
    required this.ceiling,
    required this.defaultVisibility,
    this.description,
  });

  /// The field's name, as the community shows it.
  final String label;

  /// What the field holds, in the community's words, if given.
  final String? description;

  /// Who writes the value.
  final DirectoryFieldSource source;

  /// The widest audience the value may ever reach.
  final DirectoryAudience ceiling;

  /// The audience a new card gives the value until the member chooses.
  final DirectoryAudience defaultVisibility;
}

/// What a community's member directory would disclose about a member
/// (`directoryDisclosure` of the join manifest).
class DirectoryDisclosure {
  /// Creates a [DirectoryDisclosure].
  const DirectoryDisclosure({
    required this.fields,
    required this.membershipIdentifiers,
    required this.adminNotes,
    required this.externalCards,
  });

  /// The directory's fields, in display order. A field the community does
  /// not collect is absent.
  final List<DirectoryField> fields;

  /// The widest audience the member's membership DID can reach.
  final DirectoryAudience membershipIdentifiers;

  /// Whether administrators keep notes about members, which no other member
  /// sees.
  final bool adminNotes;

  /// Whether a member may publish their card beyond the community; always
  /// their own choice.
  final bool externalCards;
}

/// What the community says about a join request
/// (`vtc/join-requests/status/0.1`).
class JoinStatus {
  /// Creates a [JoinStatus].
  const JoinStatus({
    required this.status,
    this.reason,
    this.credentialsDelivered,
  });

  /// Where the request stands.
  final JoinRequestStatus status;

  /// The community's reason for turning it down, in its own words, if any.
  final String? reason;

  /// For an approved request: whether the community holds the member's own
  /// membership credential, i.e. whether the membership was confirmed.
  final bool? credentialsDelivered;
}

/// The community's receipt for a member leaving it
/// (`vtc/members/self-remove/0.1`).
class LeaveReceipt {
  /// Creates a [LeaveReceipt].
  const LeaveReceipt({
    required this.did,
    required this.disposition,
    required this.removed,
  });

  /// The DID that left: the member's persona in the community.
  final String did;

  /// What the community keeps of the member: `purge`, `tombstone` or
  /// `historical`.
  final String disposition;

  /// Whether the community removed the member.
  final bool removed;
}
