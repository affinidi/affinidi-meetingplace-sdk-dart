// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oob_invitation_message_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OobInvitationMessageBody _$OobInvitationMessageBodyFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('OobInvitationMessageBody', json, ($checkedConvert) {
  final val = OobInvitationMessageBody(
    goalCode: $checkedConvert('goal_code', (v) => v as String),
    goal: $checkedConvert('goal', (v) => v as String),
    accept: $checkedConvert(
      'accept',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'goalCode': 'goal_code'});

Map<String, dynamic> _$OobInvitationMessageBodyToJson(
  OobInvitationMessageBody instance,
) => <String, dynamic>{
  'goal_code': instance.goalCode,
  'goal': instance.goal,
  'accept': instance.accept,
};
