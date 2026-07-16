import 'package:json_annotation/json_annotation.dart';

part 'chat_suggestion_request_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatSuggestionRequestBody {
  factory ChatSuggestionRequestBody.fromJson(Map<String, dynamic> json) =>
      _$ChatSuggestionRequestBodyFromJson(json);

  ChatSuggestionRequestBody({required this.messageId, required this.text});

  @JsonKey(name: 'message_id')
  final String messageId;

  @JsonKey(name: 'text')
  final String text;

  Map<String, dynamic> toJson() => _$ChatSuggestionRequestBodyToJson(this);
}
