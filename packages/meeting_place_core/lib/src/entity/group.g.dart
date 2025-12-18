// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Group _$GroupFromJson(Map<String, dynamic> json) => Group(
      id: json['id'] as String,
      did: json['did'] as String,
      offerLink: json['offerLink'] as String,
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      created: DateTime.parse(json['created'] as String),
      status: $enumDecodeNullable(_$GroupStatusEnumMap, json['status']) ??
          GroupStatus.created,
      ownerDid: json['ownerDid'] as String?,
      publicKey: json['publicKey'] as String?,
      externalRef: json['externalRef'] as String?,
    );

Map<String, dynamic> _$GroupToJson(Group instance) => <String, dynamic>{
      'id': instance.id,
      'did': instance.did,
      'offerLink': instance.offerLink,
      'created': instance.created.toIso8601String(),
      if (instance.externalRef case final value?) 'externalRef': value,
      if (instance.publicKey case final value?) 'publicKey': value,
      if (instance.ownerDid case final value?) 'ownerDid': value,
      'status': _$GroupStatusEnumMap[instance.status]!,
      'members': instance.members.map((e) => e.toJson()).toList(),
    };

const _$GroupStatusEnumMap = {
  GroupStatus.created: 'created',
  GroupStatus.deleted: 'deleted',
};
