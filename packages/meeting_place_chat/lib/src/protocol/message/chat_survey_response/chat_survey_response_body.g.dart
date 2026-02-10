// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_survey_response_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatSurveyResponseBody _$ChatSurveyResponseBodyFromJson(
  Map<String, dynamic> json,
) => ChatSurveyResponseBody(
  text: json['text'] as String,
  seqNo: (json['seq_no'] as num).toInt(),
  parentMessageId: json['parent_message_id'] as String,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$ChatSurveyResponseBodyToJson(
  ChatSurveyResponseBody instance,
) => <String, dynamic>{
  'parent_message_id': instance.parentMessageId,
  'text': instance.text,
  'seq_no': instance.seqNo,
  'timestamp': instance.timestamp.toIso8601String(),
};
