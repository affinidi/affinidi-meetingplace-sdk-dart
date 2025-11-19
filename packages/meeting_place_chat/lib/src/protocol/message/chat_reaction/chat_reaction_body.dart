import 'package:json_annotation/json_annotation.dart';

part 'chat_reaction_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatReactionBody {
  factory ChatReactionBody.fromJson(Map<String, dynamic> json) =>
      _$ChatReactionBodyFromJson(json);

  ChatReactionBody({required this.reactions, required this.messageId});

  @JsonKey(name: 'reactions')
  final List<String> reactions;

  @JsonKey(name: 'message_id')
  final String messageId;

  Map<String, dynamic> toJson() => _$ChatReactionBodyToJson(this);
}
