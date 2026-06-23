// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_activity_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatActivityBody _$ChatActivityBodyFromJson(Map<String, dynamic> json) =>
    ChatActivityBody(timestamp: DateTime.parse(json['timestamp'] as String));

Map<String, dynamic> _$ChatActivityBodyToJson(ChatActivityBody instance) =>
    <String, dynamic>{'timestamp': instance.timestamp.toIso8601String()};
