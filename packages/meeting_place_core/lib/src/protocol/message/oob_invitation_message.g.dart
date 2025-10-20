// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oob_invitation_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OobInvitationMessage _$OobInvitationMessageFromJson(
        Map<String, dynamic> json) =>
    OobInvitationMessage(
      id: json['id'] as String,
      from: json['from'] as String?,
    )..threadId = json['thid'] as String?;

Map<String, dynamic> _$OobInvitationMessageToJson(
        OobInvitationMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'from': instance.from,
      if (instance.threadId case final value?) 'thid': value,
    };
