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
  final String? questionMessageId;

  /// Optional stable identifier of the question.
  final String? questionId;

  /// Answer selected / free-form response.
  final String response;

  /// Creation timestamp (UTC).
  final DateTime timestamp;

  Map<String, dynamic> toJson() => _$ChatSurveyResponseBodyToJson(this);
}
