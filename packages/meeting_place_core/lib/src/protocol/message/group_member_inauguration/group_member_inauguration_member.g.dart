// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member_inauguration_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMemberInaugurationMember _$GroupMemberInaugurationMemberFromJson(
  Map<String, dynamic> json,
) => GroupMemberInaugurationMember(
  did: json['did'] as String,
  contactCardDid: json['contactCardDid'] as String,
  contactCardType: json['contactCardType'] as String,
  membershipType: json['membershipType'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$GroupMemberInaugurationMemberToJson(
  GroupMemberInaugurationMember instance,
) => <String, dynamic>{
  'did': instance.did,
  'contactCardDid': instance.contactCardDid,
  'contactCardType': instance.contactCardType,
  'membershipType': instance.membershipType,
  'status': instance.status,
};
