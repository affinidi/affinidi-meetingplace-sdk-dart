// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_group_details_update_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatGroupDetailsUpdateBody _$ChatGroupDetailsUpdateBodyFromJson(
        Map<String, dynamic> json) =>
    ChatGroupDetailsUpdateBody(
      groupId: json['group_id'] as String,
      groupDid: json['group_did'] as String,
      offerLink: json['offer_link'] as String,
      members: (json['members'] as List<dynamic>)
          .map((e) => ChatGroupDetailsUpdateBodyMember.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      adminDids: (json['admin_dids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      dateCreated: DateTime.parse(json['date_created'] as String),
      groupPublicKey: json['group_public_key'] as String,
      groupKeyPair: json['group_key_pair'] as String?,
    );

Map<String, dynamic> _$ChatGroupDetailsUpdateBodyToJson(
        ChatGroupDetailsUpdateBody instance) =>
    <String, dynamic>{
      'group_id': instance.groupId,
      'group_did': instance.groupDid,
      'offer_link': instance.offerLink,
      'members': instance.members.map((e) => e.toJson()).toList(),
      'admin_dids': instance.adminDids,
      'date_created': instance.dateCreated.toIso8601String(),
      'group_public_key': instance.groupPublicKey,
      if (instance.groupKeyPair case final value?) 'group_key_pair': value,
    };

ChatGroupDetailsUpdateBodyMember _$ChatGroupDetailsUpdateBodyMemberFromJson(
        Map<String, dynamic> json) =>
    ChatGroupDetailsUpdateBodyMember(
      did: json['did'] as String,
      contactCard: ContactCard.fromJson(json['v_card'] as Map<String, dynamic>),
      dateAdded: DateTime.parse(json['date_added'] as String),
      status: json['status'] as String,
      publicKey: json['public_key'] as String,
      membershipType: json['membership_type'] as String,
    );

Map<String, dynamic> _$ChatGroupDetailsUpdateBodyMemberToJson(
        ChatGroupDetailsUpdateBodyMember instance) =>
    <String, dynamic>{
      'did': instance.did,
      'v_card': instance.contactCard.toJson(),
      'date_added': instance.dateAdded.toIso8601String(),
      'status': instance.status,
      'public_key': instance.publicKey,
      'membership_type': instance.membershipType,
    };
