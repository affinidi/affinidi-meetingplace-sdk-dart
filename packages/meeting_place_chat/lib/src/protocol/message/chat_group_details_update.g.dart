// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_group_details_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$ChatGroupDetailsUpdateBodyMemberToJson(
        ChatGroupDetailsUpdateBodyMember instance) =>
    <String, dynamic>{
      'did': instance.did,
      'card': instance.card.toJson(),
      'dateAdded': instance.dateAdded.toIso8601String(),
      'status': instance.status,
      'publicKey': instance.publicKey,
      'membershipType': instance.membershipType,
    };
