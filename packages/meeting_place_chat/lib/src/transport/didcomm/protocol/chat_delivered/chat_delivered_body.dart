import 'package:json_annotation/json_annotation.dart';

part 'chat_delivered_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatDeliveredBody {
  factory ChatDeliveredBody.fromJson(Map<String, dynamic> json) =>
      _$ChatDeliveredBodyFromJson(json);

  ChatDeliveredBody({required this.messages});

  @JsonKey(name: 'messages')
  final List<String> messages;

  Map<String, dynamic> toJson() => _$ChatDeliveredBodyToJson(this);
}
