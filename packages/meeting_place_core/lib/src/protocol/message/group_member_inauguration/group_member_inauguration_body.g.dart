// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member_inauguration_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMemberInaugurationBody _$GroupMemberInaugurationBodyFromJson(
  Map<String, dynamic> json,
) => GroupMemberInaugurationBody(
  memberDid: json['member_did'] as String,
  groupDid: json['group_did'] as String,
  groupId: json['group_id'] as String,
  groupPublicKey: json['group_public_key'] as String,
  adminDids: (json['admin_dids'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  members: (json['members'] as List<dynamic>)
      .map(
        (e) =>
            GroupMemberInaugurationMember.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$GroupMemberInaugurationBodyToJson(
  GroupMemberInaugurationBody instance,
) => <String, dynamic>{
  'member_did': instance.memberDid,
  'group_did': instance.groupDid,
  'group_id': instance.groupId,
  'group_public_key': instance.groupPublicKey,
  'admin_dids': instance.adminDids,
  'members': instance.members.map((e) => e.toJson()).toList(),
};
