import 'package:json_annotation/json_annotation.dart';

part 'chat_activity_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatActivitiyBody {
  factory ChatActivitiyBody.fromJson(Map<String, dynamic> json) =>
      _$ChatActivitiyBodyFromJson(json);

  ChatActivitiyBody({required this.timestamp});

  @JsonKey(name: 'timestamp')
  final DateTime timestamp;

  Map<String, dynamic> toJson() => _$ChatActivitiyBodyToJson(this);
}
