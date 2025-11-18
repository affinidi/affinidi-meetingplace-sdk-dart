import 'package:json_annotation/json_annotation.dart';

part 'chat_presence_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatPresenceBody {
  factory ChatPresenceBody.fromJson(Map<String, dynamic> json) =>
      _$ChatPresenceBodyFromJson(json);

  ChatPresenceBody({required this.timestamp});

  @JsonKey(name: 'timestamp')
  final DateTime timestamp;

  Map<String, dynamic> toJson() => _$ChatPresenceBodyToJson(this);
}
