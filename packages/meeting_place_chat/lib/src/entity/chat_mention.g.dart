// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_mention.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMention _$ChatMentionFromJson(Map<String, dynamic> json) => ChatMention(
  target: json['target'] as String,
  start: (json['start'] as num).toInt(),
  length: (json['length'] as num).toInt(),
  display: json['display'] as String?,
  isRoomMention: json['isRoomMention'] as bool? ?? false,
);

Map<String, dynamic> _$ChatMentionToJson(ChatMention instance) =>
    <String, dynamic>{
      'target': instance.target,
      'start': instance.start,
      'length': instance.length,
      'display': ?instance.display,
      'isRoomMention': instance.isRoomMention,
    };
