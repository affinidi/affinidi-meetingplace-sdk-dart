import 'package:json_annotation/json_annotation.dart';

part 'chat_survey_question_body.g.dart';

/// Body for a survey question message.
///
/// Contains a free-form [question] and optional metadata for correlating
/// responses.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatSurveyQuestionBody {
  factory ChatSurveyQuestionBody.fromJson(Map<String, dynamic> json) {
    return _$ChatSurveyQuestionBodyFromJson(json);
  }
  ChatSurveyQuestionBody({
    required this.question,
    required this.suggestions,
    required this.seqNo,
    this.isAnswered = false,
    this.questionId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  /// Human-readable question.
  @JsonKey(name: 'question')
  final String question;

  /// Indicates whether the question has been answered.
  @JsonKey(name: 'is_answered')
  final bool isAnswered;

  /// Sequence number for the question (for ordering).
  @JsonKey(name: 'seq_no')
  final int seqNo;

  /// Human-readable suggestions.
  @JsonKey(name: 'suggestions')
  final List<String> suggestions;

  /// Optional stable identifier so responses can reference a question even if
  /// message IDs aren’t available.
  @JsonKey(name: 'question_id')
  final String? questionId;

  /// Creation timestamp (UTC).
  @JsonKey(name: 'timestamp')
  final DateTime timestamp;

  Map<String, dynamic> toJson() => _$ChatSurveyQuestionBodyToJson(this);
}
