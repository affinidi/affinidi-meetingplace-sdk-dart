import 'package:json_annotation/json_annotation.dart';

part 'invitation_acceptance_group_body.g.dart';

/// The body of an invitation-acceptance-group message.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class InvitationAcceptanceGroupBody {
  /// Creates an [InvitationAcceptanceGroupBody] from its JSON
  /// representation.
  factory InvitationAcceptanceGroupBody.fromJson(Map<String, dynamic> json) =>
      _$InvitationAcceptanceGroupBodyFromJson(json);

  /// Creates an [InvitationAcceptanceGroupBody].
  InvitationAcceptanceGroupBody({required this.channelDid});

  /// The DID of the accepted group channel.
  @JsonKey(name: 'channel_did')
  final String channelDid;

  /// Converts this body to its JSON representation.
  Map<String, dynamic> toJson() => _$InvitationAcceptanceGroupBodyToJson(this);
}
