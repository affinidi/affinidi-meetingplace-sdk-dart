import 'package:json_annotation/json_annotation.dart';

import '../../../entity/group_member.dart';
import '../../v_card/v_card.dart';

part 'group_member_inauguration_member.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GroupMemberInaugurationMember {
  factory GroupMemberInaugurationMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberInaugurationMemberFromJson(json);

  GroupMemberInaugurationMember({
    required this.did,
    required this.vCard,
    required this.membershipType,
    required this.status,
    required this.publicKey,
  });

  final String did;
  final VCard vCard;
  final String membershipType;
  final String status;
  final String publicKey;

  bool get isAdmin => membershipType == GroupMembershipType.admin.name;

  bool get isMember => membershipType == GroupMembershipType.member.name;

  Map<String, dynamic> toJson() => _$GroupMemberInaugurationMemberToJson(this);
}
