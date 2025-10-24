// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_group_details_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
