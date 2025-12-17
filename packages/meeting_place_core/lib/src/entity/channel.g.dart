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
              json['otherPartyContactCard'] as Map<String, dynamic>),
      outboundMessageId: json['outboundMessageId'] as String?,
      acceptOfferDid: json['acceptOfferDid'] as String?,
      permanentChannelDid: json['permanentChannelDid'] as String?,
      otherPartyPermanentChannelDid:
          json['otherPartyPermanentChannelDid'] as String?,
      notificationToken: json['notificationToken'] as String?,
      otherPartyNotificationToken:
          json['otherPartyNotificationToken'] as String?,
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
      if (instance.contactCard?.toJson() case final value?)
        'contactCard': value,
      if (instance.otherPartyContactCard?.toJson() case final value?)
        'otherPartyContactCard': value,
      'status': _$ChannelStatusEnumMap[instance.status]!,
      if (instance.outboundMessageId case final value?)
        'outboundMessageId': value,
      if (instance.acceptOfferDid case final value?) 'acceptOfferDid': value,
      if (instance.permanentChannelDid case final value?)
        'permanentChannelDid': value,
      if (instance.otherPartyPermanentChannelDid case final value?)
        'otherPartyPermanentChannelDid': value,
      if (instance.notificationToken case final value?)
        'notificationToken': value,
      if (instance.otherPartyNotificationToken case final value?)
        'otherPartyNotificationToken': value,
      if (instance.externalRef case final value?) 'externalRef': value,
      'seqNo': instance.seqNo,
      if (instance.messageSyncMarker?.toIso8601String() case final value?)
        'messageSyncMarker': value,
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
