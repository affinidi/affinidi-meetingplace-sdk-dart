import 'package:json_annotation/json_annotation.dart';

import '../../../entity/channel.dart';
import '../../../protocol/contact_card/contact_card.dart';

part 'agent_create_channel_identity_request_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AgentCreateChannelIdentityRequestBody {
  factory AgentCreateChannelIdentityRequestBody.fromJson(
    Map<String, dynamic> json,
  ) => _$AgentCreateChannelIdentityRequestBodyFromJson(json);

  AgentCreateChannelIdentityRequestBody({
    required this.channelDid,
    required this.offerLink,
    required this.publishOfferDid,
    required this.contactCard,
    required this.transport,
    this.contextKey,
  });

  @JsonKey(name: 'channelDid')
  final String channelDid;

  @JsonKey(name: 'offerLink')
  final String offerLink;

  @JsonKey(name: 'publishOfferDid')
  final String publishOfferDid;

  @JsonKey(name: 'contactCard')
  final ContactCard contactCard;

  @JsonKey(name: 'transport')
  final ChannelTransport transport;

  @JsonKey(name: 'context_key')
  final String? contextKey;

  Map<String, dynamic> toJson() =>
      _$AgentCreateChannelIdentityRequestBodyToJson(this);
}
