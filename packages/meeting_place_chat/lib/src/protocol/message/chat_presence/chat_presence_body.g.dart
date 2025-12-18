// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_presence_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatPresenceBody _$ChatPresenceBodyFromJson(Map<String, dynamic> json) =>
    ChatPresenceBody(timestamp: DateTime.parse(json['timestamp'] as String));

Map<String, dynamic> _$ChatPresenceBodyToJson(ChatPresenceBody instance) =>
    <String, dynamic>{'timestamp': instance.timestamp.toIso8601String()};
