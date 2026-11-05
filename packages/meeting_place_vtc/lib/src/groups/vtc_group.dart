/// Who a community group shows itself, or its members, to: from the
/// narrowest audience to the widest. A group's managers are always in it.
enum GroupAudience {
  /// The community's administrators only.
  admins,

  /// The group's own members.
  groupMembers,

  /// Every member of the community.
  members;

  /// The audience [value] names, or null when it names none.
  static GroupAudience? parse(Object? value) =>
      values.where((audience) => audience.name == value).firstOrNull;
}

/// Where the caller stands in a community group (`myMembership`).
enum GroupStanding {
  /// An active member.
  member,

  /// Asked to join; a manager has not decided.
  pending,

  /// Left a dynamic group whose rule still covers them.
  optedOut,

  /// None of these.
  none;

  /// The standing [value] names; [none] when it names none.
  static GroupStanding parse(Object? value) =>
      values.where((standing) => standing.name == value).firstOrNull ?? none;
}

/// A community group as the community shows it to the caller.
class VtcGroup {
  /// Creates a [VtcGroup].
  const VtcGroup({
    required this.groupId,
    required this.groupDid,
    required this.name,
    required this.isDynamic,
    required this.visibility,
    required this.showMembers,
    this.description,
    this.managers,
  });

  /// The community's id of the group, which its tasks name.
  final String groupId;

  /// The group's own `did:webvh`, held by the community's VTA: it issues
  /// the members' credentials, and a chat for the group is known by it.
  final String groupDid;

  /// The group's name.
  final String name;

  /// What the group is for, if it says.
  final String? description;

  /// Whether a rule decides the members, rather than its managers.
  final bool isDynamic;

  /// Who the community shows the group to.
  final GroupAudience visibility;

  /// Who the community shows the group's members to.
  final GroupAudience showMembers;

  /// The directory entry ids of the group's managers, which the community
  /// shows its managers only: null when the caller does not manage it.
  final List<String>? managers;

  /// Whether the caller manages the group.
  bool get isManagedByCaller => managers != null;

  /// Whether the group's members may see one another, as everyone in a
  /// chat does.
  bool get showsMembersToMembers => showMembers != GroupAudience.admins;
}

/// A community group and where the caller stands in it.
class VtcGroupListing {
  /// Creates a [VtcGroupListing].
  const VtcGroupListing({required this.group, required this.standing});

  /// The group.
  final VtcGroup group;

  /// Where the caller stands in it.
  final GroupStanding standing;
}

/// A member of a community group, as `vtc/groups/members/list` shows it.
class VtcGroupMember {
  /// Creates a [VtcGroupMember].
  const VtcGroupMember({
    required this.entryId,
    required this.state,
    this.credentialId,
  });

  /// The member's directory entry id: stable while they stay, unlike the
  /// credential the group renews.
  final String entryId;

  /// `active`, or another state such as `pending` that only managers see.
  final String state;

  /// The id of the member's current group credential, which the community
  /// shows the group's managers and the member: null to anyone else.
  final String? credentialId;

  /// Whether the member is in the group now.
  bool get isActive => state == 'active';
}
