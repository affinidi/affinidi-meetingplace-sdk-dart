// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relationship_credential_subject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelationshipCredentialSubject _$RelationshipCredentialSubjectFromJson(
  Map<String, dynamic> json,
) => RelationshipCredentialSubject(
  from: Party.fromJson(json['from'] as Map<String, dynamic>),
  to: Party.fromJson(json['to'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RelationshipCredentialSubjectToJson(
  RelationshipCredentialSubject instance,
) => <String, dynamic>{'from': instance.from, 'to': instance.to};

Party _$PartyFromJson(Map<String, dynamic> json) =>
    Party(did: json['did'] as String, name: json['name'] as String);

Map<String, dynamic> _$PartyToJson(Party instance) => <String, dynamic>{
  'did': instance.did,
  'name': instance.name,
};
