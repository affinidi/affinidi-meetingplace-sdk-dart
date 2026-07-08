// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_create_channel_identity_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentCreateChannelIdentityRequestBody
_$AgentCreateChannelIdentityRequestBodyFromJson(
  Map<String, dynamic> json,
) => AgentCreateChannelIdentityRequestBody(
  channelDid: json['channelDid'] as String,
  offerLink: json['offerLink'] as String,
  publishOfferDid: json['publishOfferDid'] as String,
  contactCard: ContactCard.fromJson(
    json['contactCard'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$AgentCreateChannelIdentityRequestBodyToJson(
  AgentCreateChannelIdentityRequestBody instance,
) => <String, dynamic>{
  'channelDid': instance.channelDid,
  if (instance.offerLink != null) 'offerLink': instance.offerLink,
  if (instance.publishOfferDid != null)
    'publishOfferDid': instance.publishOfferDid,
  if (instance.contactCard != null)
    'contactCard': instance.contactCard!.toJson(),
};
