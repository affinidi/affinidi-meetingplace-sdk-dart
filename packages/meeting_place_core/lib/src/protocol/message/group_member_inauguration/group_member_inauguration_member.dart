import 'package:json_annotation/json_annotation.dart';

import '../../../entity/group_member.dart';

part 'group_member_inauguration_member.g.dart';

/// A single group member as carried in a group-member-inauguration message
/// body.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GroupMemberInaugurationMember {
  /// Creates a [GroupMemberInaugurationMember] from its JSON representation.
  factory GroupMemberInaugurationMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberInaugurationMemberFromJson(json);

  /// Creates a [GroupMemberInaugurationMember].
  GroupMemberInaugurationMember({
    required this.did,
    required this.contactCardDid,
    required this.contactCardType,
    required this.membershipType,
    required this.status,
  });

  /// The DID of the member.
  final String did;

  /// The DID of the member's contact card.
  final String contactCardDid;

  /// The type of the member's contact card.
  final String contactCardType;

  /// The member's [GroupMembershipType], as its name.
  final String membershipType;

  /// The member's [GroupMemberStatus], as its name.
  final String status;

  /// Whether this member has admin membership.
  bool get isAdmin => membershipType == GroupMembershipType.admin.name;

  /// Whether this member has regular member (non-admin) membership.
  bool get isMember => membershipType == GroupMembershipType.member.name;

  /// Converts this member to its JSON representation.
  Map<String, dynamic> toJson() => _$GroupMemberInaugurationMemberToJson(this);
}
