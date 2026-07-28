// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vta_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VtaConfig _$VtaConfigFromJson(Map<String, dynamic> json) => VtaConfig(
  baseUrl: json['base_url'] as String,
  vtaDid: json['vta_did'] as String,
  mediatorDid: json['mediator_did'] as String?,
);

Map<String, dynamic> _$VtaConfigToJson(VtaConfig instance) => <String, dynamic>{
  'base_url': instance.baseUrl,
  'vta_did': instance.vtaDid,
  'mediator_did': instance.mediatorDid,
};
