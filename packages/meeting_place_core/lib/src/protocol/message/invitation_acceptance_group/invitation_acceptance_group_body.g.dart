// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_acceptance_group_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvitationAcceptanceGroupBody _$InvitationAcceptanceGroupBodyFromJson(
  Map<String, dynamic> json,
) => InvitationAcceptanceGroupBody(
  channelDid: json['channel_did'] as String,
  publicKey: json['public_key'] as String,
);

Map<String, dynamic> _$InvitationAcceptanceGroupBodyToJson(
  InvitationAcceptanceGroupBody instance,
) => <String, dynamic>{
  'channel_did': instance.channelDid,
  'public_key': instance.publicKey,
};
