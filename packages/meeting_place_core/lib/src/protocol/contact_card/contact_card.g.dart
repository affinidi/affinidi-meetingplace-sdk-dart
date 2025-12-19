// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactCard _$ContactCardFromJson(Map<String, dynamic> json) => ContactCard(
  did: json['did'] as String,
  type: json['type'] as String,
  contactInfo: json['contactInfo'] as Map<String, dynamic>,
);

Map<String, dynamic> _$ContactCardToJson(ContactCard instance) =>
    <String, dynamic>{
      'did': instance.did,
      'type': instance.type,
      'contactInfo': instance.contactInfo,
    };
