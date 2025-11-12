import 'package:json_annotation/json_annotation.dart';

part 'outreach_invitation_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OutreachInvitationBody {
  factory OutreachInvitationBody.fromJson(Map<String, dynamic> json) =>
      _$OutreachInvitationBodyFromJson(json);

  OutreachInvitationBody({
    required this.mnemonic,
    required this.message,
  });

  @JsonKey(name: 'mnemonic')
  final String mnemonic;

  @JsonKey(name: 'message')
  final String message;

  Map<String, dynamic> toJson() => _$OutreachInvitationBodyToJson(this);
}
