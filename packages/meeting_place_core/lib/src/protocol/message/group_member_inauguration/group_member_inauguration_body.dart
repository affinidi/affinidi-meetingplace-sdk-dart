import 'package:json_annotation/json_annotation.dart';

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

  @JsonKey(name: 'memberDid')
  final String memberDid;

  @JsonKey(name: 'groupDid')
  final String groupDid;

  @JsonKey(name: 'groupId')
  final String groupId;

  @JsonKey(name: 'groupPublicKey')
  final String groupPublicKey;

  @JsonKey(name: 'adminDids')
  final List<String> adminDids;

  @JsonKey(name: 'members')
  final List<GroupMemberInaugurationBodyMember> members;

  Map<String, dynamic> toJson() => _$GroupMemberInaugurationBodyToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GroupMemberInaugurationBodyMember {
  factory GroupMemberInaugurationBodyMember.fromJson(
          Map<String, dynamic> json) =>
      _$GroupMemberInaugurationBodyMemberFromJson(json);

  GroupMemberInaugurationBodyMember({
    required this.did,
    required this.vCard,
    required this.status,
    required this.publicKey,
    required this.isAdmin,
  });

  @JsonKey(name: 'did')
  final String did;

  @JsonKey(name: 'vCard')
  final Map<String, dynamic> vCard;

  @JsonKey(name: 'status')
  final String status;

  @JsonKey(name: 'publicKey')
  final String publicKey;

  @JsonKey(name: 'isAdmin')
  final String isAdmin;

  Map<String, dynamic> toJson() =>
      _$GroupMemberInaugurationBodyMemberToJson(this);
}
