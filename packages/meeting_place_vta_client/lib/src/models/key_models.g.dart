// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VtaKeyRecord _$VtaKeyRecordFromJson(Map<String, dynamic> json) =>
    _VtaKeyRecord(
      keyId: json['key_id'] as String,
      keyType: json['key_type'] as String,
      contextId: json['context_id'] as String?,
      label: json['label'] as String?,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$VtaKeyRecordToJson(_VtaKeyRecord instance) =>
    <String, dynamic>{
      'key_id': instance.keyId,
      'key_type': instance.keyType,
      'context_id': instance.contextId,
      'label': instance.label,
      'status': instance.status,
    };
