// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_suggestion_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatSuggestionBody _$ChatSuggestionBodyFromJson(Map<String, dynamic> json) =>
    ChatSuggestionBody(
      relatedMessageId: json['related_message_id'] as String,
      text: json['text'] as String,
    );

Map<String, dynamic> _$ChatSuggestionBodyToJson(ChatSuggestionBody instance) =>
    <String, dynamic>{
      'related_message_id': instance.relatedMessageId,
      'text': instance.text,
    };
