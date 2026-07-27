// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessageBody _$ChatMessageBodyFromJson(Map<String, dynamic> json) =>
    ChatMessageBody(
      text: json['text'] as String,
      seqNo: (json['seq_no'] as num).toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      mentions:
          (json['mentions'] as List<dynamic>?)
              ?.map((e) => ChatMention.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ChatMessageBodyToJson(ChatMessageBody instance) =>
    <String, dynamic>{
      'text': instance.text,
      'seq_no': instance.seqNo,
      'timestamp': instance.timestamp.toIso8601String(),
      'mentions': instance.mentions.map((e) => e.toJson()).toList(),
    };
