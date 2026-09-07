import 'package:json_annotation/json_annotation.dart';

part 'invitation_acceptance_body.g.dart';

/// The body of an invitation-acceptance message.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class InvitationAcceptanceBody {
  /// Creates an [InvitationAcceptanceBody] from its JSON representation.
  factory InvitationAcceptanceBody.fromJson(Map<String, dynamic> json) =>
      _$InvitationAcceptanceBodyFromJson(json);

  /// Creates an [InvitationAcceptanceBody].
  InvitationAcceptanceBody({required this.channelDid});

  /// The DID of the accepted channel.
  @JsonKey(name: 'channel_did')
  final String channelDid;

  /// Converts this body to its JSON representation.
  Map<String, dynamic> toJson() => _$InvitationAcceptanceBodyToJson(this);
}
