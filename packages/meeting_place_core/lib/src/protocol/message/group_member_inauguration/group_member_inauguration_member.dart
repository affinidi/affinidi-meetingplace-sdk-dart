import 'package:json_annotation/json_annotation.dart';

import '../../../entity/group_member.dart';

part 'group_member_inauguration_member.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GroupMemberInaugurationMember {
  factory GroupMemberInaugurationMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberInaugurationMemberFromJson(json);

  GroupMemberInaugurationMember({
    required this.did,
    required this.contactCardDid,
    required this.contactCardType,
    required this.membershipType,
    required this.status,
  });

  final String did;
  final String contactCardDid;
  final String contactCardType;
  final String membershipType;
  final String status;

  bool get isAdmin => membershipType == GroupMembershipType.admin.name;

  bool get isMember => membershipType == GroupMembershipType.member.name;

  Map<String, dynamic> toJson() => _$GroupMemberInaugurationMemberToJson(this);
}
