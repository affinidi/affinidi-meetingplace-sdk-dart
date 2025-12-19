import 'package:json_annotation/json_annotation.dart';

part 'channel_inauguration_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChannelInaugurationBody {
  factory ChannelInaugurationBody.fromJson(Map<String, dynamic> json) =>
      _$ChannelInaugurationBodyFromJson(json);

  ChannelInaugurationBody({required this.notificationToken, required this.did});

  @JsonKey(name: 'notification_token')
  final String notificationToken;

  @JsonKey(name: 'did')
  final String did;

  Map<String, dynamic> toJson() => _$ChannelInaugurationBodyToJson(this);
}
