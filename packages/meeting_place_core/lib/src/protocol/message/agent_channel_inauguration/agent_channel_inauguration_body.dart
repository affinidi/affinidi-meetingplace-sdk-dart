import 'package:json_annotation/json_annotation.dart';

import '../../../protocol/contact_card/contact_card.dart';

part 'agent_channel_inauguration_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AgentChannelInaugurationBody {
  factory AgentChannelInaugurationBody.fromJson(Map<String, dynamic> json) =>
      _$AgentChannelInaugurationBodyFromJson(json);

  AgentChannelInaugurationBody({
    required this.permanentChannelDid,
    required this.notificationToken,
    required this.offerLink,
    required this.publishOfferDid,
    this.contactCard,
  });

  @JsonKey(name: 'permanent_channel_did')
  final String permanentChannelDid;

  @JsonKey(name: 'notification_token')
  final String notificationToken;

  @JsonKey(name: 'offer_link')
  final String offerLink;

  @JsonKey(name: 'publish_offer_did')
  final String publishOfferDid;

  @JsonKey(name: 'contact_card')
  final ContactCard? contactCard;

  Map<String, dynamic> toJson() => _$AgentChannelInaugurationBodyToJson(this);
}
