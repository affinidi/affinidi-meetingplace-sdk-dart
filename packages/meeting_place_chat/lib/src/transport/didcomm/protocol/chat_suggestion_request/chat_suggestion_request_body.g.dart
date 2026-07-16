// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_suggestion_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatSuggestionRequestBody _$ChatSuggestionRequestBodyFromJson(
  Map<String, dynamic> json,
) => ChatSuggestionRequestBody(
  messageId: json['message_id'] as String,
  text: json['text'] as String,
);

Map<String, dynamic> _$ChatSuggestionRequestBodyToJson(
  ChatSuggestionRequestBody instance,
) => <String, dynamic>{'message_id': instance.messageId, 'text': instance.text};
