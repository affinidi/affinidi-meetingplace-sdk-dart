// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMember _$GroupMemberFromJson(Map<String, dynamic> json) => GroupMember(
      did: json['did'] as String,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      status: $enumDecode(_$GroupMemberStatusEnumMap, json['status']),
      membershipType:
          $enumDecode(_$GroupMembershipTypeEnumMap, json['membershipType']),
      vCard: ContactCard.fromJson(json['vCard'] as Map<String, dynamic>),
      publicKey: json['publicKey'] as String,
    );

Map<String, dynamic> _$GroupMemberToJson(GroupMember instance) =>
    <String, dynamic>{
      'did': instance.did,
      'dateAdded': instance.dateAdded.toIso8601String(),
      'membershipType': _$GroupMembershipTypeEnumMap[instance.membershipType]!,
      'publicKey': instance.publicKey,
      'vCard': instance.vCard.toJson(),
      'status': _$GroupMemberStatusEnumMap[instance.status]!,
    };

const _$GroupMemberStatusEnumMap = {
  GroupMemberStatus.pendingApproval: 'pendingApproval',
  GroupMemberStatus.pendingInauguration: 'pendingInauguration',
  GroupMemberStatus.approved: 'approved',
  GroupMemberStatus.rejected: 'rejected',
  GroupMemberStatus.error: 'error',
  GroupMemberStatus.deleted: 'deleted',
};

const _$GroupMembershipTypeEnumMap = {
  GroupMembershipType.admin: 'admin',
  GroupMembershipType.member: 'member',
};
