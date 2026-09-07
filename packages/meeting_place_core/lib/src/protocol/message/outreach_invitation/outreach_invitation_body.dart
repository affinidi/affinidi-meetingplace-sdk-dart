import 'package:json_annotation/json_annotation.dart';

part 'outreach_invitation_body.g.dart';

/// The body of an outreach-invitation message.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OutreachInvitationBody {
  /// Creates an [OutreachInvitationBody] from its JSON representation.
  factory OutreachInvitationBody.fromJson(Map<String, dynamic> json) =>
      _$OutreachInvitationBodyFromJson(json);

  /// Creates an [OutreachInvitationBody].
  OutreachInvitationBody({required this.mnemonic, required this.message});

  /// A short mnemonic identifying the outreach campaign or context.
  @JsonKey(name: 'mnemonic')
  final String mnemonic;

  /// The human-readable outreach message text.
  @JsonKey(name: 'message')
  final String message;

  /// Converts this body to its JSON representation.
  Map<String, dynamic> toJson() => _$OutreachInvitationBodyToJson(this);
}
