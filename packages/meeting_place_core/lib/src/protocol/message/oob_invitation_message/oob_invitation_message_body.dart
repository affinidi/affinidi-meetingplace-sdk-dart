import 'package:json_annotation/json_annotation.dart';

part 'oob_invitation_message_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OobInvitationMessageBody {
  factory OobInvitationMessageBody.fromJson(Map<String, dynamic> json) =>
      _$OobInvitationMessageBodyFromJson(json);

  OobInvitationMessageBody({
    required this.goalCode,
    required this.goal,
    required this.accept,
  });

  @JsonKey(name: 'goal_code')
  final String goalCode;

  @JsonKey(name: 'goal')
  final String goal;

  @JsonKey(name: 'accept')
  final List<String> accept;

  Map<String, dynamic> toJson() => _$OobInvitationMessageBodyToJson(this);
}
