// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_activity_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatActivityBody _$ChatActivitiyBodyFromJson(Map<String, dynamic> json) =>
    ChatActivityBody(
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$ChatActivitiyBodyToJson(ChatActivityBody instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
    };
