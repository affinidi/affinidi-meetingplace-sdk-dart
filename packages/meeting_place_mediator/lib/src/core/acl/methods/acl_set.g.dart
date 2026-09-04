// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'acl_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccessListSet _$AccessListSetFromJson(Map<String, dynamic> json) =>
    AccessListSet(
      ownerDid: json['did_hash'] as String,
      acls: (json['acls'] as num).toInt(),
    );

Map<String, dynamic> _$AccessListSetToJson(AccessListSet instance) =>
    <String, dynamic>{'did_hash': instance.ownerDid, 'acls': instance.acls};
