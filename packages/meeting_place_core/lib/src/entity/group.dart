import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import 'group_member.dart';

part 'group.g.dart';

enum GroupStatus { created, deleted }

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Group {
  factory Group.fromJson(Map<String, dynamic> json) {
    return _$GroupFromJson(json);
  }

  Group({
    required this.id,
    required this.did,
    required this.offerLink,
    required this.members,
    required this.created,
    this.status = GroupStatus.created,
    this.ownerDid,
    this.publicKey,
    this.externalRef,
  });

  final String id;
  final String did;
  final String offerLink;
  final DateTime created;
  final String? externalRef;

  // For members added later
  final String? publicKey;
  final String? ownerDid;

  GroupStatus status;

  @JsonKey(defaultValue: [])
  final List<GroupMember> members;

  Map<String, dynamic> toJson() {
    return _$GroupToJson(this);
  }

  void approveMember(GroupMember member) {
    members.firstWhere((m) => m.did == member.did).status =
        GroupMemberStatus.approved;
  }

  Group copyWith({
    String? id,
    String? did,
    String? offerLink,
    List<GroupMember>? members,
    DateTime? created,
    String? ownerDid,
    String? groupKeyPair,
    String? publicKey,
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
      publicKey: publicKey ?? this.publicKey,
      externalRef: externalRef ?? this.externalRef,
    );
  }

  bool isMemberOfTypeAdmin(String memberDid) {
    return members.firstWhereOrNull(
          (member) =>
              member.did == memberDid &&
              member.membershipType == GroupMembershipType.admin,
        ) !=
        null;
  }

  List<GroupMember> getGroupMembersWaitingForApproval() {
    return members
        .where((member) => member.status == GroupMemberStatus.pendingApproval)
        .toList();
  }

  void markAsDeleted() {
    status = GroupStatus.deleted;
  }

  bool get isDeleted => status == GroupStatus.deleted;
}
