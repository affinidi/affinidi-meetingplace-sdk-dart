// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_survey_response_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatSurveyResponseBody _$ChatSurveyResponseBodyFromJson(
  Map<String, dynamic> json,
) => ChatSurveyResponseBody(
  response: json['response'] as String,
  questionMessageId: json['questionMessageId'] as String?,
  questionId: json['questionId'] as String?,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$ChatSurveyResponseBodyToJson(
  ChatSurveyResponseBody instance,
) => <String, dynamic>{
  'questionMessageId': ?instance.questionMessageId,
  'questionId': ?instance.questionId,
  'response': instance.response,
  'timestamp': instance.timestamp.toIso8601String(),
};
