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
    );

Map<String, dynamic> _$ChatMessageBodyToJson(ChatMessageBody instance) =>
    <String, dynamic>{
      'text': instance.text,
      'seq_no': instance.seqNo,
      'timestamp': instance.timestamp.toIso8601String(),
    };
