// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'acl_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AclSet _$AclSetFromJson(Map<String, dynamic> json) => AclSet(
      ownerDid: json['did_hash'] as String,
      acls: (json['acls'] as num).toInt(),
    );

Map<String, dynamic> _$AclSetToJson(AclSet instance) => <String, dynamic>{
      'did_hash': instance.ownerDid,
      'acls': instance.acls,
    };
