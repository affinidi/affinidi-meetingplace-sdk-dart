import 'package:json_annotation/json_annotation.dart';

part 'connection_request_approval_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ConnectionRequestApprovalBody {
  factory ConnectionRequestApprovalBody.fromJson(Map<String, dynamic> json) =>
      _$ConnectionRequestApprovalBodyFromJson(json);

  ConnectionRequestApprovalBody({required this.channelDid, this.agentDid});

  @JsonKey(name: 'channel_did')
  final String channelDid;

  @JsonKey(name: 'agent_did')
  final String? agentDid;

  Map<String, dynamic> toJson() => _$ConnectionRequestApprovalBodyToJson(this);
}
