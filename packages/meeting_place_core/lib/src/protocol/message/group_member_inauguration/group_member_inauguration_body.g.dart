// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member_inauguration_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMemberInaugurationBody _$GroupMemberInaugurationBodyFromJson(
        Map<String, dynamic> json) =>
    GroupMemberInaugurationBody(
      memberDid: json['memberDid'] as String,
      groupDid: json['groupDid'] as String,
      groupId: json['groupId'] as String,
      groupPublicKey: json['groupPublicKey'] as String,
      adminDids:
          (json['adminDids'] as List<dynamic>).map((e) => e as String).toList(),
      members: (json['members'] as List<dynamic>)
          .map((e) => GroupMemberInaugurationBodyMember.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GroupMemberInaugurationBodyToJson(
        GroupMemberInaugurationBody instance) =>
    <String, dynamic>{
      'memberDid': instance.memberDid,
      'groupDid': instance.groupDid,
      'groupId': instance.groupId,
      'groupPublicKey': instance.groupPublicKey,
      'adminDids': instance.adminDids,
      'members': instance.members.map((e) => e.toJson()).toList(),
    };

GroupMemberInaugurationBodyMember _$GroupMemberInaugurationBodyMemberFromJson(
        Map<String, dynamic> json) =>
    GroupMemberInaugurationBodyMember(
      did: json['did'] as String,
      vCard: json['vCard'] as Map<String, dynamic>,
      status: json['status'] as String,
      publicKey: json['publicKey'] as String,
      isAdmin: json['isAdmin'] as String,
    );

Map<String, dynamic> _$GroupMemberInaugurationBodyMemberToJson(
        GroupMemberInaugurationBodyMember instance) =>
    <String, dynamic>{
      'did': instance.did,
      'vCard': instance.vCard,
      'status': instance.status,
      'publicKey': instance.publicKey,
      'isAdmin': instance.isAdmin,
    };
