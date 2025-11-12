// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_activity_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatActivitiyBody _$ChatActivitiyBodyFromJson(Map<String, dynamic> json) =>
    ChatActivitiyBody(
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$ChatActivitiyBodyToJson(ChatActivitiyBody instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
    };
