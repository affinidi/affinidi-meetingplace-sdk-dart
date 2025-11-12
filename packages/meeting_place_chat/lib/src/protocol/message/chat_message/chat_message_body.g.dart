// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessageBody _$ChatMessageBodyFromJson(Map<String, dynamic> json) =>
    ChatMessageBody(
      text: json['text'] as String,
      seqNo: (json['seqNo'] as num).toInt(),
    );

Map<String, dynamic> _$ChatMessageBodyToJson(ChatMessageBody instance) =>
    <String, dynamic>{
      'text': instance.text,
      'seqNo': instance.seqNo,
    };
