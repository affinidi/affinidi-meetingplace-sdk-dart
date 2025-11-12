import 'package:json_annotation/json_annotation.dart';

part 'invitation_acceptance_group_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class InvitationAcceptanceGroupBody {
  factory InvitationAcceptanceGroupBody.fromJson(Map<String, dynamic> json) =>
      _$InvitationAcceptanceGroupBodyFromJson(json);

  InvitationAcceptanceGroupBody({
    required this.channelDid,
    required this.publicKey,
  });

  @JsonKey(name: 'channel_did')
  final String channelDid;

  @JsonKey(name: 'public_key')
  final String publicKey;

  Map<String, dynamic> toJson() =>
      _$InvitationAcceptanceGroupBodyToJson(this);
}
