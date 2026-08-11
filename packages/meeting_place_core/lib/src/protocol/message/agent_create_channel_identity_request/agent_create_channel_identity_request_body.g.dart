// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_create_channel_identity_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentCreateChannelIdentityRequestBody
_$AgentCreateChannelIdentityRequestBodyFromJson(Map<String, dynamic> json) =>
    AgentCreateChannelIdentityRequestBody(
      channelDid: json['channelDid'] as String,
      offerLink: json['offerLink'] as String,
      publishOfferDid: json['publishOfferDid'] as String,
      contactCard: ContactCard.fromJson(
        json['contactCard'] as Map<String, dynamic>,
      ),
      transport: $enumDecode(_$ChannelTransportEnumMap, json['transport']),
      channelType: $enumDecodeNullable(
        _$ChannelTypeEnumMap,
        json['channelType'],
      ),
      contextKey: json['context_key'] as String?,
    );

Map<String, dynamic> _$AgentCreateChannelIdentityRequestBodyToJson(
  AgentCreateChannelIdentityRequestBody instance,
) => <String, dynamic>{
  'channelDid': instance.channelDid,
  'offerLink': instance.offerLink,
  'publishOfferDid': instance.publishOfferDid,
  'contactCard': instance.contactCard.toJson(),
  'transport': _$ChannelTransportEnumMap[instance.transport]!,
  'channelType': ?_$ChannelTypeEnumMap[instance.channelType],
  'context_key': ?instance.contextKey,
};

const _$ChannelTypeEnumMap = {
  ChannelType.individual: 'individual',
  ChannelType.group: 'group',
  ChannelType.oob: 'oob',
};

const _$ChannelTransportEnumMap = {
  ChannelTransport.didcomm: 'didcomm',
  ChannelTransport.matrix: 'matrix',
};
