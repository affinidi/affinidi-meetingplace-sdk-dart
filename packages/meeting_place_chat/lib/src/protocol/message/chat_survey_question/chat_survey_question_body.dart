import 'package:json_annotation/json_annotation.dart';

part 'chat_survey_question_body.g.dart';

/// Body for a survey question message.
///
/// Contains a free-form [question] and optional metadata for correlating
/// responses.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatSurveyQuestionBody {
  ChatSurveyQuestionBody({
    required this.question,
    this.questionId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  factory ChatSurveyQuestionBody.fromJson(Map<String, dynamic> json) {
    return _$ChatSurveyQuestionBodyFromJson(json);
  }

  /// Human-readable question.
  final String question;

  /// Optional stable identifier so responses can reference a question even if
  /// message IDs aren’t available.
  final String? questionId;

  /// Creation timestamp (UTC).
  final DateTime timestamp;

  Map<String, dynamic> toJson() => _$ChatSurveyQuestionBodyToJson(this);
}
