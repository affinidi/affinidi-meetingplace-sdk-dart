// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_list_remove.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccessListRemove _$AccessListRemoveFromJson(Map<String, dynamic> json) =>
    AccessListRemove(
      ownerDid: json['did_hash'] as String,
      granteeDids:
          (json['hashes'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$AccessListRemoveToJson(AccessListRemove instance) =>
    <String, dynamic>{
      'did_hash': instance.ownerDid,
      'hashes': instance.granteeDids,
    };
