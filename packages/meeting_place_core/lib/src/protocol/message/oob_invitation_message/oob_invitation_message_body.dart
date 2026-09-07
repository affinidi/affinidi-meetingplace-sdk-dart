import 'package:json_annotation/json_annotation.dart';

part 'oob_invitation_message_body.g.dart';

/// The body of an out-of-band invitation message.
@JsonSerializable(includeIfNull: false, explicitToJson: true, checked: true)
class OobInvitationMessageBody {
  /// Creates an [OobInvitationMessageBody] from its JSON representation.
  factory OobInvitationMessageBody.fromJson(Map<String, dynamic> json) =>
      _$OobInvitationMessageBodyFromJson(json);

  /// Creates an [OobInvitationMessageBody].
  OobInvitationMessageBody({
    required this.goalCode,
    required this.goal,
    required this.accept,
  });

  /// A machine-readable code identifying the invitation's goal, e.g.
  /// `'connect'`.
  @JsonKey(name: 'goal_code')
  final String goalCode;

  /// A human-readable description of the invitation's goal.
  @JsonKey(name: 'goal')
  final String goal;

  /// The DIDComm message formats the inviter accepts, e.g. `'didcomm/v2'`.
  @JsonKey(name: 'accept')
  final List<String> accept;

  /// Converts this body to its JSON representation.
  Map<String, dynamic> toJson() => _$OobInvitationMessageBodyToJson(this);
}
