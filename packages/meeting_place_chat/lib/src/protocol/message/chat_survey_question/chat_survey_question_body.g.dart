// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_survey_question_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatSurveyQuestionBody _$ChatSurveyQuestionBodyFromJson(
  Map<String, dynamic> json,
) => ChatSurveyQuestionBody(
  question: json['question'] as String,
  suggestions: (json['suggestions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  seqNo: (json['seq_no'] as num).toInt(),
  isAnswered: json['is_answered'] as bool? ?? false,
  questionId: json['question_id'] as String?,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$ChatSurveyQuestionBodyToJson(
  ChatSurveyQuestionBody instance,
) => <String, dynamic>{
  'question': instance.question,
  'is_answered': instance.isAnswered,
  'seq_no': instance.seqNo,
  'suggestions': instance.suggestions,
  'question_id': ?instance.questionId,
  'timestamp': instance.timestamp.toIso8601String(),
};
