// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_channel_inauguration_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentChannelInaugurationBody _$AgentChannelInaugurationBodyFromJson(
  Map<String, dynamic> json,
) => AgentChannelInaugurationBody(
  permanentChannelDid: json['permanent_channel_did'] as String,
  notificationToken: json['notification_token'] as String,
);

Map<String, dynamic> _$AgentChannelInaugurationBodyToJson(
  AgentChannelInaugurationBody instance,
) => <String, dynamic>{
  'permanent_channel_did': instance.permanentChannelDid,
  'notification_token': instance.notificationToken,
};
