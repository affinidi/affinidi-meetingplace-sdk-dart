import 'package:json_annotation/json_annotation.dart';

import 'group_member_inauguration_member.dart';

part 'group_member_inauguration_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GroupMemberInaugurationBody {
  factory GroupMemberInaugurationBody.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberInaugurationBodyFromJson(json);

  GroupMemberInaugurationBody({
    required this.memberDid,
    required this.groupDid,
    required this.groupId,
    required this.groupPublicKey,
    required this.adminDids,
    required this.members,
  });

  @JsonKey(name: 'member_did')
  final String memberDid;

  @JsonKey(name: 'group_did')
  final String groupDid;

  @JsonKey(name: 'group_id')
  final String groupId;

  @JsonKey(name: 'group_public_key')
  final String groupPublicKey;

  @JsonKey(name: 'admin_dids')
  final List<String> adminDids;

  @JsonKey(name: 'members')
  final List<GroupMemberInaugurationMember> members;

  Map<String, dynamic> toJson() => _$GroupMemberInaugurationBodyToJson(this);
}
