import 'package:json_annotation/json_annotation.dart';

part 'chat_survey_response_body.g.dart';

/// Body for a survey response message.
///
/// Links the response to a question via [questionMessageId] or [questionId].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatSurveyResponseBody {
  ChatSurveyResponseBody({
    required this.response,
    this.questionMessageId,
    this.questionId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  factory ChatSurveyResponseBody.fromJson(Map<String, dynamic> json) {
    return _$ChatSurveyResponseBodyFromJson(json);
  }

  /// PlainTextMessage.id of the original question message.
  @JsonKey(name: 'question_message_id')
  final String? questionMessageId;

  /// Optional stable identifier of the question.
  @JsonKey(name: 'question_id')
  final String? questionId;

  /// Answer selected / free-form response.
  @JsonKey(name: 'response')
  final String response;

  /// Creation timestamp (UTC).
  @JsonKey(name: 'timestamp')
  final DateTime timestamp;

  Map<String, dynamic> toJson() => _$ChatSurveyResponseBodyToJson(this);
}
