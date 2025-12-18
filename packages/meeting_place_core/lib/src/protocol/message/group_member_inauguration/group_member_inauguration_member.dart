import 'package:json_annotation/json_annotation.dart';

import '../../../entity/group_member.dart';
import '../../contact_card/contact_card.dart';

part 'group_member_inauguration_member.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GroupMemberInaugurationMember {
  factory GroupMemberInaugurationMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberInaugurationMemberFromJson(json);

  GroupMemberInaugurationMember({
    required this.did,
    required this.contactCard,
    required this.membershipType,
    required this.status,
    required this.publicKey,
  });

  final String did;
  final ContactCard contactCard;
  final String membershipType;
  final String status;
  final String publicKey;

  bool get isAdmin => membershipType == GroupMembershipType.admin.name;

  bool get isMember => membershipType == GroupMembershipType.member.name;

  Map<String, dynamic> toJson() => _$GroupMemberInaugurationMemberToJson(this);
}
