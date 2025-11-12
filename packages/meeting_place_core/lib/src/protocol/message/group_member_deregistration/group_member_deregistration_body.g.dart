// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member_deregistration_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMemberDeregistrationBody _$GroupMemberDeregistrationBodyFromJson(
        Map<String, dynamic> json) =>
    GroupMemberDeregistrationBody(
      groupId: json['groupId'] as String,
      memberDid: json['memberDid'] as String,
    );

Map<String, dynamic> _$GroupMemberDeregistrationBodyToJson(
        GroupMemberDeregistrationBody instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'memberDid': instance.memberDid,
    };
