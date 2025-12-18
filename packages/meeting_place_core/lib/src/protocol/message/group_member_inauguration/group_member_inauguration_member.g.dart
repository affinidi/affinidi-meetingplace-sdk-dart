// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member_inauguration_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMemberInaugurationMember _$GroupMemberInaugurationMemberFromJson(
        Map<String, dynamic> json) =>
    GroupMemberInaugurationMember(
      did: json['did'] as String,
      contactCard:
          ContactCard.fromJson(json['contactCard'] as Map<String, dynamic>),
      membershipType: json['membershipType'] as String,
      status: json['status'] as String,
      publicKey: json['publicKey'] as String,
    );

Map<String, dynamic> _$GroupMemberInaugurationMemberToJson(
        GroupMemberInaugurationMember instance) =>
    <String, dynamic>{
      'did': instance.did,
      'contactCard': instance.contactCard.toJson(),
      'membershipType': instance.membershipType,
      'status': instance.status,
      'publicKey': instance.publicKey,
    };
