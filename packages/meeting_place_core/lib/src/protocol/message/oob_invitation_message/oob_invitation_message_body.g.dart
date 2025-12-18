// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oob_invitation_message_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OobInvitationMessageBody _$OobInvitationMessageBodyFromJson(
        Map<String, dynamic> json) =>
    OobInvitationMessageBody(
      goalCode: json['goal_code'] as String,
      goal: json['goal'] as String,
      accept:
          (json['accept'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$OobInvitationMessageBodyToJson(
        OobInvitationMessageBody instance) =>
    <String, dynamic>{
      'goal_code': instance.goalCode,
      'goal': instance.goal,
      'accept': instance.accept,
    };
