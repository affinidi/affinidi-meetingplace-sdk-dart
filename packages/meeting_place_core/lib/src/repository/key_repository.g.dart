// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyPair _$KeyPairFromJson(Map<String, dynamic> json) => KeyPair(
      publicKeyBytes: KeyPair._bytesFromJson(json['publicKeyBytes'] as List),
      privateKeyBytes: KeyPair._bytesFromJson(json['privateKeyBytes'] as List),
    );

Map<String, dynamic> _$KeyPairToJson(KeyPair instance) => <String, dynamic>{
      'publicKeyBytes': instance.publicKeyBytes,
      'privateKeyBytes': instance.privateKeyBytes,
    };
