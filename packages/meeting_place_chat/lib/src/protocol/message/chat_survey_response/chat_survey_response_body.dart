import 'package:json_annotation/json_annotation.dart';

part 'chat_survey_response_body.g.dart';

/// Body for a survey response message.
///
/// Links the response to a question via [messageId] or [questionId].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatSurveyResponseBody {
  ChatSurveyResponseBody({
    required this.text,
    required this.seqNo,
    required this.parentMessageId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  factory ChatSurveyResponseBody.fromJson(Map<String, dynamic> json) {
    return _$ChatSurveyResponseBodyFromJson(json);
  }

  /// PlainTextMessage.id of the original question message.
  @JsonKey(name: 'parent_message_id')
  final String parentMessageId;

  /// Answer selected / free-form response.
  @JsonKey(name: 'text')
  final String text;

  /// Sequence number of the response.
  @JsonKey(name: 'seq_no')
  final int seqNo;

  /// Creation timestamp (UTC).
  @JsonKey(name: 'timestamp')
  final DateTime timestamp;

  Map<String, dynamic> toJson() => _$ChatSurveyResponseBodyToJson(this);
}
