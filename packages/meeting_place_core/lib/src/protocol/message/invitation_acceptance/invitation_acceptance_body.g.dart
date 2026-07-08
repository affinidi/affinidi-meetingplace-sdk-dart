// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_acceptance_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvitationAcceptanceBody _$InvitationAcceptanceBodyFromJson(
  Map<String, dynamic> json,
) => InvitationAcceptanceBody(
  channelDid: json['channel_did'] as String,
  agentDid: json['agent_did'] as String?,
);

Map<String, dynamic> _$InvitationAcceptanceBodyToJson(
  InvitationAcceptanceBody instance,
) {
  final val = <String, dynamic>{'channel_did': instance.channelDid};
  if (instance.agentDid != null) {
    val['agent_did'] = instance.agentDid;
  }
  return val;
}
