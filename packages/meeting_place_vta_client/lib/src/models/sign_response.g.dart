// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignResponse _$SignResponseFromJson(Map<String, dynamic> json) => SignResponse(
  signature: json['signature'] as String,
  algorithm: json['algorithm'] as String?,
  keyId: json['key_id'] as String?,
);

Map<String, dynamic> _$SignResponseToJson(SignResponse instance) =>
    <String, dynamic>{
      'signature': instance.signature,
      'algorithm': instance.algorithm,
      'key_id': instance.keyId,
    };
