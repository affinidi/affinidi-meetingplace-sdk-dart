// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'did_secrets_bundle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DidSecretEntry _$DidSecretEntryFromJson(Map<String, dynamic> json) =>
    _DidSecretEntry(
      keyId: json['key_id'] as String,
      keyType: json['key_type'] as String,
      privateKeyMultibase: json['private_key_multibase'] as String,
    );

Map<String, dynamic> _$DidSecretEntryToJson(_DidSecretEntry instance) =>
    <String, dynamic>{
      'key_id': instance.keyId,
      'key_type': instance.keyType,
      'private_key_multibase': instance.privateKeyMultibase,
    };

_DidSecretsBundle _$DidSecretsBundleFromJson(Map<String, dynamic> json) =>
    _DidSecretsBundle(
      did: json['did'] as String,
      secrets: (json['secrets'] as List<dynamic>)
          .map((e) => DidSecretEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DidSecretsBundleToJson(_DidSecretsBundle instance) =>
    <String, dynamic>{'did': instance.did, 'secrets': instance.secrets};
