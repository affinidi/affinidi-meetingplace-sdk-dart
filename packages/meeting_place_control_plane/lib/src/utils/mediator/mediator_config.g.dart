// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mediator_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediatorConfig _$MediatorConfigFromJson(Map<String, dynamic> json) =>
    MediatorConfig(
      mediatorDid: json['mediatorDid'] as String,
      mediatorEndpoint: json['mediatorEndpoint'] as String,
      mediatorWSSEndpoint: json['mediatorWSSEndpoint'] as String,
      secondsBeforeExpiryReauthenticate:
          (json['secondsBeforeExpiryReauthenticate'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MediatorConfigToJson(MediatorConfig instance) =>
    <String, dynamic>{
      'mediatorDid': instance.mediatorDid,
      'mediatorEndpoint': instance.mediatorEndpoint,
      'mediatorWSSEndpoint': instance.mediatorWSSEndpoint,
      'secondsBeforeExpiryReauthenticate':
          ?instance.secondsBeforeExpiryReauthenticate,
    };
