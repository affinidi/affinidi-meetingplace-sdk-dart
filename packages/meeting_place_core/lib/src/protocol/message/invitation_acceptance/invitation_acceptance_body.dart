import 'package:json_annotation/json_annotation.dart';

part 'invitation_acceptance_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class InvitationAcceptanceBody {
  factory InvitationAcceptanceBody.fromJson(Map<String, dynamic> json) =>
      _$InvitationAcceptanceBodyFromJson(json);

  InvitationAcceptanceBody({required this.channelDid, this.agentDid});

  @JsonKey(name: 'channel_did')
  final String channelDid;

  @JsonKey(name: 'agent_did')
  final String? agentDid;

  Map<String, dynamic> toJson() => _$InvitationAcceptanceBodyToJson(this);
}
