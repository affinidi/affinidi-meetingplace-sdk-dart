import 'package:json_annotation/json_annotation.dart';

part 'agent_create_channel_identity_response_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AgentCreateChannelIdentityResponseBody {
  factory AgentCreateChannelIdentityResponseBody.fromJson(
    Map<String, dynamic> json,
  ) => _$AgentCreateChannelIdentityResponseBodyFromJson(json);

  AgentCreateChannelIdentityResponseBody({required this.did});

  @JsonKey(name: 'did')
  final String did;

  Map<String, dynamic> toJson() =>
      _$AgentCreateChannelIdentityResponseBodyToJson(this);
}
