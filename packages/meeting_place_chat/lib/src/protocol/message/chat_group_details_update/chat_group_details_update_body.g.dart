// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_group_details_update_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatGroupDetailsUpdateBody _$ChatGroupDetailsUpdateBodyFromJson(
        Map<String, dynamic> json) =>
    ChatGroupDetailsUpdateBody(
      groupId: json['groupId'] as String,
      groupDid: json['groupDid'] as String,
      offerLink: json['offerLink'] as String,
      members: (json['members'] as List<dynamic>)
          .map((e) => ChatGroupDetailsUpdateBodyMember.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      adminDids:
          (json['adminDids'] as List<dynamic>).map((e) => e as String).toList(),
      dateCreated: DateTime.parse(json['dateCreated'] as String),
      groupPublicKey: json['groupPublicKey'] as String,
      groupKeyPair: json['groupKeyPair'] as String?,
    );

Map<String, dynamic> _$ChatGroupDetailsUpdateBodyToJson(
        ChatGroupDetailsUpdateBody instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'groupDid': instance.groupDid,
      'offerLink': instance.offerLink,
      'members': instance.members.map((e) => e.toJson()).toList(),
      'adminDids': instance.adminDids,
      'dateCreated': instance.dateCreated.toIso8601String(),
      'groupPublicKey': instance.groupPublicKey,
      if (instance.groupKeyPair case final value?) 'groupKeyPair': value,
    };

ChatGroupDetailsUpdateBodyMember _$ChatGroupDetailsUpdateBodyMemberFromJson(
        Map<String, dynamic> json) =>
    ChatGroupDetailsUpdateBodyMember(
      did: json['did'] as String,
      vCard: VCard.fromJson(json['vCard'] as Map<String, dynamic>),
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      status: json['status'] as String,
      publicKey: json['publicKey'] as String,
      membershipType: json['membershipType'] as String,
    );

Map<String, dynamic> _$ChatGroupDetailsUpdateBodyMemberToJson(
        ChatGroupDetailsUpdateBodyMember instance) =>
    <String, dynamic>{
      'did': instance.did,
      'vCard': instance.vCard.toJson(),
      'dateAdded': instance.dateAdded.toIso8601String(),
      'status': instance.status,
      'publicKey': instance.publicKey,
      'membershipType': instance.membershipType,
    };
