// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_inauguration_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChannelInaugurationBody _$ChannelInaugurationBodyFromJson(
        Map<String, dynamic> json) =>
    ChannelInaugurationBody(
      notificationToken: json['notification_token'] as String,
      did: json['did'] as String,
    );

Map<String, dynamic> _$ChannelInaugurationBodyToJson(
        ChannelInaugurationBody instance) =>
    <String, dynamic>{
      'notification_token': instance.notificationToken,
      'did': instance.did,
    };
