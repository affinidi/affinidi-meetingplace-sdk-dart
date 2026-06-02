// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_list_add.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccessListAdd _$AccessListAddFromJson(Map<String, dynamic> json) =>
    AccessListAdd(
      ownerDid: json['did_hash'] as String,
      granteeDids:
          (json['hashes'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$AccessListAddToJson(AccessListAdd instance) =>
    <String, dynamic>{
      'did_hash': instance.ownerDid,
      'hashes': instance.granteeDids,
    };
