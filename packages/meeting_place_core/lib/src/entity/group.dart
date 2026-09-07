import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import 'group_member.dart';

part 'group.g.dart';

/// The stage of a [Group] in its lifecycle.
enum GroupStatus {
  /// The group has been created.
  created,

  /// The group has been deleted.
  deleted,
}

/// A group of parties connected through group connection offers.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Group {
  /// Creates a [Group] from its JSON representation.
  factory Group.fromJson(Map<String, dynamic> json) {
    return _$GroupFromJson(json);
  }

  /// Creates a [Group].
  Group({
    required this.id,
    required this.did,
    required this.offerLink,
    required this.members,
    required this.created,
    this.status = GroupStatus.created,
    this.ownerDid,
    this.externalRef,
  });

  /// Unique identifier for the group.
  final String id;

  /// DID of the group.
  final String did;

  /// Offer identifier that can be used to correlate the group with the
  /// group connection offer.
  final String offerLink;

  /// When the group was created.
  final DateTime created;

  /// External reference that can be used to correlate the group with
  /// external systems. This field is not used by the SDK, and can be set by
  /// the SDK consumer to store any relevant information.
  final String? externalRef;

  /// DID of the group's owner.
  final String? ownerDid;

  /// The current stage of the group in its lifecycle.
  GroupStatus status;

  /// The group's members.
  @JsonKey(defaultValue: [])
  final List<GroupMember> members;

  /// Converts this group to its JSON representation.
  Map<String, dynamic> toJson() {
    return _$GroupToJson(this);
  }

  /// Returns a copy of this group with the given fields replaced.
  Group copyWith({
    String? id,
    String? did,
    String? offerLink,
    List<GroupMember>? members,
    DateTime? created,
    String? ownerDid,
    String? externalRef,
  }) {
    return Group(
      id: id ?? this.id,
      did: did ?? this.did,
      status: status,
      offerLink: offerLink ?? this.offerLink,
      members: members ?? this.members,
      created: created ?? this.created,
      ownerDid: ownerDid ?? this.ownerDid,
      externalRef: externalRef ?? this.externalRef,
    );
  }

  /// Whether the member with DID [memberDid] has admin membership of this
  /// group.
  bool isMemberOfTypeAdmin(String memberDid) {
    return members.firstWhereOrNull(
          (member) =>
              member.did == memberDid &&
              member.membershipType == GroupMembershipType.admin,
        ) !=
        null;
  }

  /// Returns the members currently waiting for approval.
  List<GroupMember> getGroupMembersWaitingForApproval() {
    return members
        .where((member) => member.status == GroupMemberStatus.pendingApproval)
        .toList();
  }

  /// Marks this group as deleted.
  void markAsDeleted() {
    status = GroupStatus.deleted;
  }

  /// Whether this group is in the deleted status.
  bool get isDeleted => status == GroupStatus.deleted;
}
