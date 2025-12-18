// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member_deregistration_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMemberDeregistrationBody _$GroupMemberDeregistrationBodyFromJson(
  Map<String, dynamic> json,
) => GroupMemberDeregistrationBody(
  groupId: json['group_id'] as String,
  memberDid: json['member_did'] as String,
);

Map<String, dynamic> _$GroupMemberDeregistrationBodyToJson(
  GroupMemberDeregistrationBody instance,
) => <String, dynamic>{
  'group_id': instance.groupId,
  'member_did': instance.memberDid,
};
