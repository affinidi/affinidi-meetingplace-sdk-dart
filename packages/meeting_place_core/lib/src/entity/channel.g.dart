// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Channel _$ChannelFromJson(Map<String, dynamic> json) => Channel(
  id: json['id'] as String?,
  offerLink: json['offerLink'] as String,
  publishOfferDid: json['publishOfferDid'] as String,
  mediatorDid: json['mediatorDid'] as String,
  status: $enumDecode(_$ChannelStatusEnumMap, json['status']),
  contactCard: json['contactCard'] == null
      ? null
      : ContactCard.fromJson(json['contactCard'] as Map<String, dynamic>),
  type: $enumDecode(_$ChannelTypeEnumMap, json['type']),
  otherPartyContactCard: json['otherPartyContactCard'] == null
      ? null
      : ContactCard.fromJson(
          json['otherPartyContactCard'] as Map<String, dynamic>,
        ),
  outboundMessageId: json['outboundMessageId'] as String?,
  acceptOfferDid: json['acceptOfferDid'] as String?,
  permanentChannelDid: json['permanentChannelDid'] as String?,
  otherPartyPermanentChannelDid:
      json['otherPartyPermanentChannelDid'] as String?,
  notificationToken: json['notificationToken'] as String?,
  otherPartyNotificationToken: json['otherPartyNotificationToken'] as String?,
  messageSyncMarker: json['messageSyncMarker'] == null
      ? null
      : DateTime.parse(json['messageSyncMarker'] as String),
  seqNo: (json['seqNo'] as num?)?.toInt() ?? 0,
  externalRef: json['externalRef'] as String?,
);

Map<String, dynamic> _$ChannelToJson(Channel instance) => <String, dynamic>{
  'id': instance.id,
  'publishOfferDid': instance.publishOfferDid,
  'mediatorDid': instance.mediatorDid,
  'offerLink': instance.offerLink,
  'type': _$ChannelTypeEnumMap[instance.type]!,
  'contactCard': ?instance.contactCard?.toJson(),
  'otherPartyContactCard': ?instance.otherPartyContactCard?.toJson(),
  'status': _$ChannelStatusEnumMap[instance.status]!,
  'outboundMessageId': ?instance.outboundMessageId,
  'acceptOfferDid': ?instance.acceptOfferDid,
  'permanentChannelDid': ?instance.permanentChannelDid,
  'otherPartyPermanentChannelDid': ?instance.otherPartyPermanentChannelDid,
  'notificationToken': ?instance.notificationToken,
  'otherPartyNotificationToken': ?instance.otherPartyNotificationToken,
  'externalRef': ?instance.externalRef,
  'seqNo': instance.seqNo,
  'messageSyncMarker': ?instance.messageSyncMarker?.toIso8601String(),
};

const _$ChannelStatusEnumMap = {
  ChannelStatus.waitingForApproval: 'waitingForApproval',
  ChannelStatus.inaugurated: 'inaugurated',
  ChannelStatus.approved: 'approved',
};

const _$ChannelTypeEnumMap = {
  ChannelType.individual: 'individual',
  ChannelType.group: 'group',
  ChannelType.oob: 'oob',
};
