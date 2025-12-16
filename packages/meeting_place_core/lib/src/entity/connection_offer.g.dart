// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_offer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectionOffer _$ConnectionOfferFromJson(Map<String, dynamic> json) =>
    ConnectionOffer(
      offerName: json['offerName'] as String,
      offerLink: json['offerLink'] as String,
      mnemonic: json['mnemonic'] as String,
      publishOfferDid: json['publishOfferDid'] as String,
      mediatorDid: json['mediatorDid'] as String,
      oobInvitationMessage: json['oobInvitationMessage'] as String,
      type: $enumDecode(_$ConnectionOfferTypeEnumMap, json['type']),
      status: $enumDecode(_$ConnectionOfferStatusEnumMap, json['status']),
      contactCard: ContactCard.fromJson(json['card'] as Map<String, dynamic>),
      ownedByMe: json['ownedByMe'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      maximumUsage: (json['maximumUsage'] as num?)?.toInt(),
      offerDescription: json['offerDescription'] as String?,
      outboundMessageId: json['outboundMessageId'] as String?,
      acceptOfferDid: json['acceptOfferDid'] as String?,
      permanentChannelDid: json['permanentChannelDid'] as String?,
      otherPartyPermanentChannelDid:
          json['otherPartyPermanentChannelDid'] as String?,
      notificationToken: json['notificationToken'] as String?,
      otherPartyNotificationToken:
          json['otherPartyNotificationToken'] as String?,
      externalRef: json['externalRef'] as String?,
    );

Map<String, dynamic> _$ConnectionOfferToJson(ConnectionOffer instance) =>
    <String, dynamic>{
      'offerName': instance.offerName,
      'offerLink': instance.offerLink,
      if (instance.offerDescription case final value?)
        'offerDescription': value,
      'mnemonic': instance.mnemonic,
      'createdAt': instance.createdAt.toIso8601String(),
      'publishOfferDid': instance.publishOfferDid,
      'mediatorDid': instance.mediatorDid,
      'oobInvitationMessage': instance.oobInvitationMessage,
      'card': instance.contactCard.toJson(),
      'type': _$ConnectionOfferTypeEnumMap[instance.type]!,
      'status': _$ConnectionOfferStatusEnumMap[instance.status]!,
      'ownedByMe': instance.ownedByMe,
      if (instance.expiresAt?.toIso8601String() case final value?)
        'expiresAt': value,
      if (instance.maximumUsage case final value?) 'maximumUsage': value,
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
    };

const _$ConnectionOfferTypeEnumMap = {
  ConnectionOfferType.meetingPlaceInvitation: 'meetingPlaceInvitation',
  ConnectionOfferType.meetingPlaceOutreachInvitation:
      'meetingPlaceOutreachInvitation',
};

const _$ConnectionOfferStatusEnumMap = {
  ConnectionOfferStatus.published: 'published',
  ConnectionOfferStatus.finalised: 'finalised',
  ConnectionOfferStatus.accepted: 'accepted',
  ConnectionOfferStatus.channelInaugurated: 'channelInaugurated',
  ConnectionOfferStatus.deleted: 'deleted',
};
