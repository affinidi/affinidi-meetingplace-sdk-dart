import 'package:json_annotation/json_annotation.dart';

part 'agent_channel_inauguration_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AgentChannelInaugurationBody {
  factory AgentChannelInaugurationBody.fromJson(Map<String, dynamic> json) =>
      _$AgentChannelInaugurationBodyFromJson(json);

  AgentChannelInaugurationBody({
    required this.permanentChannelDid,
    required this.notificationToken,
  });

  @JsonKey(name: 'permanent_channel_did')
  final String permanentChannelDid;

  @JsonKey(name: 'notification_token')
  final String notificationToken;

  Map<String, dynamic> toJson() => _$AgentChannelInaugurationBodyToJson(this);
}
