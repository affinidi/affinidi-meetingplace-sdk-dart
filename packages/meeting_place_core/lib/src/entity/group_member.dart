import 'package:json_annotation/json_annotation.dart';
import '../protocol/contact_card/contact_card.dart';

part 'group_member.g.dart';

/// The stage of a [GroupMember] in its lifecycle.
enum GroupMemberStatus {
  /// The member is waiting for an admin to approve them.
  pendingApproval,

  /// The member has been approved and is waiting to be inaugurated.
  pendingInauguration,

  /// The member has been approved.
  approved,

  /// The member's request to join was rejected.
  rejected,

  /// An error occurred while processing the member.
  error,

  /// The member has been removed from the group.
  deleted,
}

/// The kind of membership a [GroupMember] holds within a group.
enum GroupMembershipType {
  /// The member has admin privileges within the group.
  admin,

  /// The member has regular (non-admin) membership.
  member,
}

/// A member of a group.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GroupMember {
  /// Creates a [GroupMember] with [GroupMemberStatus.pendingApproval] status
  /// and regular membership.
  factory GroupMember.pendingMember({
    required String did,
    required ContactCard contactCard,
  }) {
    return GroupMember(
      did: did,
      dateAdded: DateTime.now().toUtc(),
      status: GroupMemberStatus.pendingApproval,
      membershipType: GroupMembershipType.member,
      contactCard: contactCard,
    );
  }

  /// Creates a [GroupMember] with [GroupMemberStatus.approved] status and
  /// admin membership.
  factory GroupMember.admin({
    required String did,
    required ContactCard contactCard,
  }) {
    return GroupMember(
      did: did,
      dateAdded: DateTime.now().toUtc(),
      status: GroupMemberStatus.approved,
      membershipType: GroupMembershipType.admin,
      contactCard: contactCard,
    );
  }

  /// Creates a [GroupMember] from its JSON representation.
  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return _$GroupMemberFromJson(json);
  }

  /// Creates a [GroupMember].
  GroupMember({
    required this.did,
    required this.dateAdded,
    required this.status,
    required this.membershipType,
    required this.contactCard,
  });

  /// The DID of the member.
  final String did;

  /// When the member was added to the group.
  final DateTime dateAdded;

  /// The kind of membership the member holds.
  final GroupMembershipType membershipType;

  /// Contact card of the member.
  ContactCard contactCard;

  /// The current stage of the member in its lifecycle.
  GroupMemberStatus status;

  /// Converts this member to its JSON representation.
  Map<String, dynamic> toJson() {
    return _$GroupMemberToJson(this);
  }

  /// Returns a copy of this member with the given fields replaced.
  GroupMember copyWith({
    String? did,
    DateTime? dateAdded,
    GroupMemberStatus? status,
    GroupMembershipType? membershipType,
    ContactCard? card,
  }) {
    return GroupMember(
      did: did ?? this.did,
      dateAdded: dateAdded ?? this.dateAdded,
      status: status ?? this.status,
      membershipType: membershipType ?? this.membershipType,
      contactCard: card ?? contactCard,
    );
  }
}
