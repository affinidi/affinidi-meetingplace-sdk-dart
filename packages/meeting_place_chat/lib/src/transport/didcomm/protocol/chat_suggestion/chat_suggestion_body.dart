import 'package:json_annotation/json_annotation.dart';

part 'chat_suggestion_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatSuggestionBody {
  factory ChatSuggestionBody.fromJson(Map<String, dynamic> json) =>
      _$ChatSuggestionBodyFromJson(json);

  ChatSuggestionBody({required this.relatedMessageId, required this.text});

  @JsonKey(name: 'related_message_id')
  final String relatedMessageId;

  @JsonKey(name: 'text')
  final String text;

  Map<String, dynamic> toJson() => _$ChatSuggestionBodyToJson(this);
}