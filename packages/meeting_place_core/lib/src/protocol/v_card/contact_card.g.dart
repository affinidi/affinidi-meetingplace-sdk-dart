// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactCard _$ContactCardFromJson(Map<String, dynamic> json) => ContactCard(
      did: json['did'] as String,
      contactType: json['contactType'] as String,
      info: json['info'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$ContactCardToJson(ContactCard instance) =>
    <String, dynamic>{
      'did': instance.did,
      'contactType': instance.contactType,
      'info': instance.info,
    };
