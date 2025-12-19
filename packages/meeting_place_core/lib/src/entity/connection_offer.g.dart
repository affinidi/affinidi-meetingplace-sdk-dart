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
      contactCard: ContactCard.fromJson(
        json['contactCard'] as Map<String, dynamic>,
      ),
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
      'offerDescription': ?instance.offerDescription,
      'mnemonic': instance.mnemonic,
      'createdAt': instance.createdAt.toIso8601String(),
      'publishOfferDid': instance.publishOfferDid,
      'mediatorDid': instance.mediatorDid,
      'oobInvitationMessage': instance.oobInvitationMessage,
      'contactCard': instance.contactCard.toJson(),
      'type': _$ConnectionOfferTypeEnumMap[instance.type]!,
      'status': _$ConnectionOfferStatusEnumMap[instance.status]!,
      'ownedByMe': instance.ownedByMe,
      'expiresAt': ?instance.expiresAt?.toIso8601String(),
      'maximumUsage': ?instance.maximumUsage,
      'outboundMessageId': ?instance.outboundMessageId,
      'acceptOfferDid': ?instance.acceptOfferDid,
      'permanentChannelDid': ?instance.permanentChannelDid,
      'otherPartyPermanentChannelDid': ?instance.otherPartyPermanentChannelDid,
      'notificationToken': ?instance.notificationToken,
      'otherPartyNotificationToken': ?instance.otherPartyNotificationToken,
      'externalRef': ?instance.externalRef,
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
