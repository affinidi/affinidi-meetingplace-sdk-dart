// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'r_card_subject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RCardSubject _$RCardSubjectFromJson(Map<String, dynamic> json) => RCardSubject(
  id: json['id'] as String?,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  company: json['company'] as String?,
  position: json['position'] as String?,
  website: json['website'] as String?,
  social: json['social'] as String?,
  profilePic: json['profilePic'] as String?,
);

Map<String, dynamic> _$RCardSubjectToJson(RCardSubject instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'company': instance.company,
      'position': instance.position,
      'website': instance.website,
      'social': instance.social,
      'profilePic': instance.profilePic,
    };
