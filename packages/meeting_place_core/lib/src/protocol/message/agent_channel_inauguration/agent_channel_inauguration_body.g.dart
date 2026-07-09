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
  offerLink: json['offer_link'] as String,
  publishOfferDid: json['publish_offer_did'] as String,
  contactCard: json['contact_card'] == null
      ? null
      : ContactCard.fromJson(json['contact_card'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AgentChannelInaugurationBodyToJson(
  AgentChannelInaugurationBody instance,
) => <String, dynamic>{
  'permanent_channel_did': instance.permanentChannelDid,
  'notification_token': instance.notificationToken,
  'offer_link': instance.offerLink,
  'publish_offer_did': instance.publishOfferDid,
  if (instance.contactCard != null)
    'contact_card': instance.contactCard!.toJson(),
};
