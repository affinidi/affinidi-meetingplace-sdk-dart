import 'package:json_annotation/json_annotation.dart';

part 'chat_activity_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatActivityBody {
  factory ChatActivityBody.fromJson(Map<String, dynamic> json) =>
      _$ChatActivitiyBodyFromJson(json);

  ChatActivityBody({required this.timestamp});

  @JsonKey(name: 'timestamp')
  final DateTime timestamp;

  Map<String, dynamic> toJson() => _$ChatActivitiyBodyToJson(this);
}
