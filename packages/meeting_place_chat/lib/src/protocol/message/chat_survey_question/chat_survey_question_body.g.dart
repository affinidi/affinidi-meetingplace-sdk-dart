// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_survey_question_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatSurveyQuestionBody _$ChatSurveyQuestionBodyFromJson(
  Map<String, dynamic> json,
) => ChatSurveyQuestionBody(
  question: json['question'] as String,
  questionId: json['questionId'] as String?,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$ChatSurveyQuestionBodyToJson(
  ChatSurveyQuestionBody instance,
) => <String, dynamic>{
  'question': instance.question,
  'questionId': ?instance.questionId,
  'timestamp': instance.timestamp.toIso8601String(),
};
